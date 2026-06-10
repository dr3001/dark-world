import pino from "pino";
import { config } from "./config.js";

export const logger = pino({
  level: config.logLevel,
  transport: {
    target: "pino-pretty",
    options: { colorize: true, translateTime: "HH:MM:ss" },
  },
});

export function audit(action: string, details: Record<string, unknown> = {}) {
  logger.info({ type: "audit", action, ...details }, `[AUDIT] ${action}`);
}
