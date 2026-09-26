import { Injectable } from "@nestjs/common";

@Injectable()
export class EnvService {
  get<T extends string | number = string>(key: string, fallback: T): T {
    const value = process.env[key];
    if (value === undefined || value === "") return fallback;
    return (typeof fallback === "number" ? Number(value) : value) as T;
  }

  getOrThrow<T = string>(key: string): T {
    const value = process.env[key];
    if (!value)
      throw new Error(`Missing required environment variable: ${key}`);
    return value as T;
  }
}
