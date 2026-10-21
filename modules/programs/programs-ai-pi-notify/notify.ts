/**
 * Desktop notifications for pi, routed through the same `claude-notify.sh`
 * that drives Claude Code's - see modules/programs/programs-ai-pi-notify.
 *
 * That script is written against Claude Code's hook contract: one subcommand
 * per event, with the event's JSON payload on stdin. pi has no hook system, so
 * this extension is the adapter - it maps pi's extension events onto those
 * subcommands and synthesises the payload fields the script reads
 * (`session_id`, `cwd`, `message`, `last_assistant_message`).
 *
 * The binary is resolved from PI_NOTIFY_BIN, which the module pins to a store
 * path, so this does not depend on PATH inside whatever shell launched pi.
 */

import { spawn } from "node:child_process";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const NOTIFY_BIN = process.env.PI_NOTIFY_BIN ?? "pi-notify";

/**
 * The script's `send` detaches a popup that outlives this call, so there is
 * nothing to await and nothing to report. A missing binary or a broken pipe is
 * swallowed deliberately: a notification is never worth failing a turn over.
 */
function fire(action: string, payload: Record<string, unknown>): void {
	try {
		const child = spawn(NOTIFY_BIN, [action], {
			stdio: ["pipe", "ignore", "ignore"],
			detached: true,
		});
		child.on("error", () => {});
		child.stdin?.on("error", () => {});
		child.stdin?.end(JSON.stringify(payload));
		child.unref();
	} catch {
		// ignored
	}
}

function base(ctx: ExtensionContext): Record<string, unknown> {
	const session = ctx.sessionManager;
	return {
		session_id: session?.getSessionId?.() ?? "unknown",
		cwd: session?.getCwd?.() ?? ctx.cwd,
	};
}

/** Pull the plain text out of a finalized assistant message, shape-tolerantly. */
function messageText(message: unknown): string {
	const content = (message as { content?: unknown })?.content;
	if (typeof content === "string") return content;
	if (!Array.isArray(content)) return "";
	return content
		.filter((block) => (block as { type?: string })?.type === "text")
		.map((block) => (block as { text?: string }).text ?? "")
		.join(" ")
		.trim();
}

export default function (pi: ExtensionAPI) {
	// The script's stop path reports how long the turn took, so it needs the
	// start stamp and the last thing the agent said.
	let lastAssistantText = "";
	// The bus handler below is handed data, not a context. Keeping the last one
	// seen matters: the popup's replace-id is keyed on the session, so an
	// attention popup raised with a different id would stack beside the
	// start/stop popups instead of superseding them.
	let lastContext: ExtensionContext | undefined;

	pi.on("session_start", (_event, ctx) => {
		lastContext = ctx;
	});

	pi.on("before_agent_start", (_event, ctx) => {
		lastContext = ctx;
		lastAssistantText = "";
		fire("start", base(ctx));
	});

	pi.on("message_end", (event, _ctx) => {
		const message = event.message as { role?: string };
		if (message?.role !== "assistant") return;
		const text = messageText(event.message);
		if (text) lastAssistantText = text;
	});

	// Not `agent_end`: pi may still retry, compact, or run a queued follow-up
	// after one. `agent_settled` is the point where it will not continue on its
	// own, which is what "the long thing finished" has to mean.
	pi.on("agent_settled", (event, ctx) => {
		if (event.aborted) return;
		fire("stop", { ...base(ctx), last_assistant_message: lastAssistantText });
	});

	// Claude Code's Notification hook equivalent. Two sources, because they
	// cover different prompts and either may be absent:
	//   - ui_prompt_start is pi's own signal for a blocking extension prompt
	//     (ctx.ui.select/confirm/input), e.g. rpiv-ask-user-question.
	//   - pi-permission-system draws its own inline keybind dialog and
	//     announces it on the extension bus instead.
	// A popup reuses one notification id per session, so a doubled event
	// replaces rather than stacks.
	pi.on("ui_prompt_start", (event, ctx) => {
		fire("attention", {
			...base(ctx),
			message: event.title ?? "pi is waiting on you.",
		});
	});

	pi.events.on("permissions:ui_prompt", (data) => {
		const tool = (data as { toolName?: string })?.toolName;
		fire("attention", {
			session_id: lastContext ? base(lastContext).session_id : "unknown",
			cwd: lastContext?.cwd ?? process.cwd(),
			message: tool ? `Permission requested for ${tool}.` : "Permission requested.",
		});
	});
}
