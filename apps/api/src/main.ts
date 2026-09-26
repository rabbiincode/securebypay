import "./config/load-env";
import { ValidationPipe } from "@nestjs/common";
import { NestFactory } from "@nestjs/core";
import { DocumentBuilder, SwaggerModule } from "@nestjs/swagger";
import cookieParser = require("cookie-parser");
import helmet from "helmet";
import type { NextFunction, Request, Response } from "express";
import { AppModule } from "./app.module";
import { EnvService } from "./config/env.service";

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const config = app.get(EnvService);
  app.setGlobalPrefix("api");
  app.use(helmet());
  app.use(cookieParser());
  const allowedOrigins = config
    .get("WEB_URL", "http://localhost:3000")
    .split(",")
    .map((origin) => origin.trim());
  app.enableCors({ origin: allowedOrigins, credentials: true });
  app.use((request: Request, response: Response, next: NextFunction) => {
    if (
      request.method !== "GET" &&
      request.headers.origin &&
      !allowedOrigins.includes(request.headers.origin)
    ) {
      response.status(403).json({ message: "Origin not allowed" });
      return;
    }
    next();
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  const document = SwaggerModule.createDocument(
    app,
    new DocumentBuilder()
      .setTitle("SecureByPay API")
      .setVersion("1.0")
      .addBearerAuth()
      .build(),
  );
  SwaggerModule.setup("api/docs", app, document);
  await app.listen(config.get<number>("API_PORT", 4000), "0.0.0.0");
}
void bootstrap();
