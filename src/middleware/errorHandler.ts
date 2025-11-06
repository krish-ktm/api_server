import { Request, Response, NextFunction } from "express";
import util from "util";

type Err = Error & { statusCode?: number; info?: any };

export const asyncHandler =
  (fn: any) =>
  (req: any, res: any, next: any) =>
    Promise.resolve(fn(req, res, next)).catch(next);

export const errorHandler = (err: Err, req: Request, res: Response, next: NextFunction) => {
  // Strong logging for debugging
  try {
    console.error("==== Unhandled Error ====");
    console.error(util.inspect(err, { showHidden: true, depth: 6 }));
    if (err.stack) console.error(err.stack);
    console.error("=========================");
  } catch (loggingErr) {
    console.error("Error while logging error:", loggingErr);
  }

  const status = err.statusCode || (err as any).status || 500;
  const message = err.message || "Server error";

  const payload: any = { success: false, message };

  if (process.env.NODE_ENV !== "production") {
    payload.error = {
      message: err.message,
      stack: err.stack,
      info: err.info ?? undefined,
    };
  }

  res.status(status).json(payload);
};