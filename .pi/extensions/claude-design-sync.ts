import { mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { StringEnum } from "@earendil-works/pi-ai";
import {
	DEFAULT_MAX_BYTES,
	DEFAULT_MAX_LINES,
	formatSize,
	truncateTail,
	type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const DEFAULT_TIMEOUT_MS = 20 * 60 * 1000;
const MAX_TIMEOUT_MS = 60 * 60 * 1000;

const ClaudeDesignSyncParams = Type.Object({
	task: Type.String({
		minLength: 1,
		description: "The design-sync task for Claude Code to complete in the current project.",
	}),
	permissionMode: Type.Optional(
		StringEnum(["acceptEdits", "bypassPermissions"] as const, {
			description:
				"Claude Code permission mode. Use bypassPermissions only when the user explicitly authorizes unattended commands and edits. Defaults to acceptEdits.",
		}),
	),
	timeoutMs: Type.Optional(
		Type.Integer({
			minimum: 10_000,
			maximum: MAX_TIMEOUT_MS,
			description: `Maximum run time in milliseconds (default ${DEFAULT_TIMEOUT_MS}).`,
		}),
	),
	maxBudgetUsd: Type.Optional(
		Type.Number({
			minimum: 0.01,
			description: "Optional maximum Claude Code API spend in US dollars.",
		}),
	),
});

interface ClaudeDesignSyncDetails {
	task: string;
	permissionMode: "acceptEdits" | "bypassPermissions";
	exitCode: number | null;
	fullOutputPath?: string;
	truncated: boolean;
}

async function formatOutput(output: string): Promise<{
	text: string;
	fullOutputPath?: string;
	truncated: boolean;
}> {
	const truncation = truncateTail(output, {
		maxLines: DEFAULT_MAX_LINES,
		maxBytes: DEFAULT_MAX_BYTES,
	});

	if (!truncation.truncated) {
		return { text: truncation.content || "(Claude Code produced no output.)", truncated: false };
	}

	const outputDirectory = await mkdtemp(join(tmpdir(), "pi-claude-design-sync-"));
	const fullOutputPath = join(outputDirectory, "output.txt");
	await writeFile(fullOutputPath, output, { encoding: "utf8", mode: 0o600 });

	const omittedLines = truncation.totalLines - truncation.outputLines;
	const omittedBytes = truncation.totalBytes - truncation.outputBytes;
	const notice = [
		`[Output truncated: showing the last ${truncation.outputLines} of ${truncation.totalLines} lines`,
		`(${formatSize(truncation.outputBytes)} of ${formatSize(truncation.totalBytes)}).`,
		`${omittedLines} lines (${formatSize(omittedBytes)}) omitted.`,
		`Full output saved to: ${fullOutputPath}]`,
	].join(" ");

	return { text: `${notice}\n\n${truncation.content}`, fullOutputPath, truncated: true };
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "claude_design_sync",
		label: "Claude Design Sync",
		description: [
			"Run a design-sync task in Claude Code, where the DesignSync tool can access the cloud design system.",
			`Output is truncated to the last ${DEFAULT_MAX_LINES} lines or ${formatSize(DEFAULT_MAX_BYTES)}; full truncated output is saved to a private temporary file.`,
		].join(" "),
		promptSnippet: "Run an explicitly requested design-sync task with Claude Code",
		promptGuidelines: [
			"Use claude_design_sync only when the user explicitly asks to run a design-sync task; do not use it for ordinary coding or design advice.",
			"Set claude_design_sync permissionMode to bypassPermissions only when the user explicitly authorizes Claude Code to make unattended edits and run commands.",
		],
		parameters: ClaudeDesignSyncParams,

		async execute(_toolCallId, params, signal, onUpdate) {
			const permissionMode = params.permissionMode ?? "acceptEdits";
			const args = [
				"--print",
				"--output-format",
				"text",
				"--no-session-persistence",
				"--permission-mode",
				permissionMode,
			];

			if (permissionMode === "bypassPermissions") args.push("--allow-dangerously-skip-permissions");
			if (params.maxBudgetUsd !== undefined) args.push("--max-budget-usd", String(params.maxBudgetUsd));

			args.push(
				[
					"Complete this design-sync task in the current project directory.",
					"Use Claude Code's DesignSync tool for cloud design-system work; do not invoke the generic /design-sync converter.",
					"The tracked design-system directory is a partial mirror: make only surgical, additive cloud writes to exact paths and never delete cloud files.",
					"Follow the repository instructions and report the changes and validation performed.",
					"",
					params.task,
				].join("\n"),
			);

			onUpdate?.({ content: [{ type: "text", text: "Running Claude Code design-sync task..." }] });

			const result = await pi.exec("claude", args, {
				signal,
				timeout: params.timeoutMs ?? DEFAULT_TIMEOUT_MS,
			});
			const rawOutput = [
				result.stdout.trim(),
				result.stderr.trim() ? `--- stderr ---\n${result.stderr.trim()}` : "",
			]
				.filter(Boolean)
				.join("\n\n");
			const output = await formatOutput(rawOutput);

			if (result.code !== 0) {
				throw new Error(`Claude Code exited with status ${result.code ?? "unknown"}.\n\n${output.text}`);
			}

			return {
				content: [{ type: "text", text: output.text }],
				details: {
					task: params.task,
					permissionMode,
					exitCode: result.code,
					fullOutputPath: output.fullOutputPath,
					truncated: output.truncated,
				} satisfies ClaudeDesignSyncDetails,
			};
		},
	});
}
