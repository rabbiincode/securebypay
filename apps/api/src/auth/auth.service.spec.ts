import { ChallengePurpose } from '@prisma/client';
import * as argon2 from 'argon2';
import { createHmac } from 'node:crypto';
import { describe, expect, it, jest } from '@jest/globals';
import { AuthService } from './auth.service';

describe('AuthService', () => {
  const asyncMock = <T = unknown>() => jest.fn<(...args: unknown[]) => Promise<T>>();
  const resolved = <T>(value: T) => jest.fn<(...args: unknown[]) => Promise<T>>().mockResolvedValue(value);
  const secret = 'otp-secret-at-least-32-characters';
  const user = {
    id: 'user-1', email: 'person@example.com', firstName: 'Person', lastName: 'Example',
    phoneNumber: null, passwordHash: '', emailVerified: new Date(), createdAt: new Date(), updatedAt: new Date(), walletBalance: 0,
  };

  function setup() {
    const tx = {
      verificationChallenge: {
        updateMany: resolved({ count: 0 }),
        create: resolved({ id: 'challenge-1' }),
      },
      notificationOutbox: { upsert: resolved({}) },
    };
    const prisma = {
      user: { findUnique: asyncMock<unknown>(), create: asyncMock<unknown>(), update: asyncMock<unknown>() },
      session: { create: asyncMock<unknown>(), findUnique: asyncMock<unknown>(), update: asyncMock<unknown>(), updateMany: asyncMock<unknown>() },
      verificationChallenge: { findUnique: asyncMock<unknown>(), update: asyncMock<unknown>(), updateMany: asyncMock<unknown>() },
      auditEvent: { create: resolved({}) },
      $transaction: jest.fn(async (value: unknown) => typeof value === 'function' ? (value as (client: typeof tx) => unknown)(tx) : Promise.all(value as Promise<unknown>[])),
    };
    const jwt = { signAsync: resolved('token'), verifyAsync: resolved({}) };
    const config = { getOrThrow: jest.fn((key: string) => key === 'OTP_HASH_SECRET' ? secret : `${key}-with-a-long-development-secret`), get: jest.fn((_: string, fallback: string) => fallback) };
    const notifications = { enqueue: jest.fn(async (client: typeof tx, input: { idempotencyKey: string }) => client.notificationOutbox.upsert({ where: { idempotencyKey: input.idempotencyKey }, create: input, update: {} })), processPending: jest.fn() };
    return { service: new AuthService(prisma as never, jwt as never, config as never, notifications as never), prisma, notifications, tx };
  }

  it('requires an email code after a valid password instead of issuing tokens', async () => {
    const { service, prisma, notifications } = setup();
    user.passwordHash = await argon2.hash('correct-password');
    prisma.user.findUnique.mockResolvedValue(user);

    const result = await service.login({ email: user.email, password: 'correct-password' });

    expect(result).toMatchObject({ requiresVerification: true, challengeId: 'challenge-1', destination: 'p***@example.com' });
    expect(result).not.toHaveProperty('accessToken');
    expect(notifications.enqueue).toHaveBeenCalledWith(expect.anything(), expect.objectContaining({ idempotencyKey: 'SIGN_IN_CODE:challenge-1' }));
  });

  it('issues a session only after consuming the correct sign-in code', async () => {
    const { service, prisma } = setup();
    const code = '123456';
    prisma.verificationChallenge.findUnique.mockResolvedValue({
      id: 'challenge-1', purpose: ChallengePurpose.SIGN_IN, consumedAt: null, expiresAt: new Date(Date.now() + 60_000), attempts: 0,
      codeHash: createHmac('sha256', secret).update(code).digest('hex'), user,
    });
    prisma.verificationChallenge.updateMany.mockResolvedValue({ count: 1 });
    prisma.session.create.mockResolvedValue({});

    const result = await service.verifySignIn('challenge-1', code);

    expect(result).toHaveProperty('accessToken', 'token');
    expect(result).toHaveProperty('refreshToken', 'token');
    expect(prisma.verificationChallenge.updateMany).toHaveBeenCalledWith(expect.objectContaining({ where: { id: 'challenge-1', consumedAt: null } }));
  });

  it('counts invalid code attempts without consuming the challenge', async () => {
    const { service, prisma } = setup();
    prisma.verificationChallenge.findUnique.mockResolvedValue({
      id: 'challenge-1', purpose: ChallengePurpose.SIGN_IN, consumedAt: null, expiresAt: new Date(Date.now() + 60_000), attempts: 0,
      codeHash: createHmac('sha256', secret).update('123456').digest('hex'), user,
    });
    prisma.verificationChallenge.update.mockResolvedValue({});

    await expect(service.verifySignIn('challenge-1', '999999')).rejects.toThrow('invalid or expired');
    expect(prisma.verificationChallenge.update).toHaveBeenCalledWith(expect.objectContaining({ data: { attempts: { increment: 1 } } }));
    expect(prisma.session.create).not.toHaveBeenCalled();
  });

  it('rotates a valid refresh session and revokes the old token', async () => {
    const { service, prisma } = setup();
    prisma.session.findUnique.mockResolvedValue({ id: 'session-1', revokedAt: null, expiresAt: new Date(Date.now() + 60_000), user });
    prisma.session.update.mockResolvedValue({});
    prisma.session.create.mockResolvedValue({});

    const result = await service.refresh('existing-refresh-token');

    expect(prisma.session.update).toHaveBeenCalledWith({ where: { id: 'session-1' }, data: { revokedAt: expect.any(Date) } });
    expect(result).toHaveProperty('refreshToken', 'token');
  });
});
