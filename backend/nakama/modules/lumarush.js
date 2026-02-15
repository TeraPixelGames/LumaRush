var DEFAULT_LEADERBOARD_ID = "lumarush_high_scores";
var PLAYER_STATS_COLLECTION = "lumarush_player_stats";
var PLAYER_STATS_KEY = "high_score";
var MODULE_CONFIG = {
  leaderboardId: DEFAULT_LEADERBOARD_ID,
  authUrl: "",
  eventUrl: "",
  apiKey: "",
  httpTimeoutMs: 5000,
};

function InitModule(ctx, logger, nk, initializer) {
  MODULE_CONFIG = loadConfig(ctx);
  ensureLeaderboard(nk, logger, MODULE_CONFIG.leaderboardId);

  initializer.registerRpc("tpx_submit_score", rpcSubmitScore);
  initializer.registerRpc("tpx_get_my_high_score", rpcGetMyHighScore);
  initializer.registerRpc("tpx_list_leaderboard", rpcListLeaderboard);

  initializer.registerBeforeAuthenticateCustom(beforeAuthenticateCustom);
  initializer.registerBeforeAuthenticateDevice(beforeAuthenticateDevice);
  initializer.registerAfterAuthenticateCustom(afterAuthenticateCustom);
  initializer.registerAfterAuthenticateDevice(afterAuthenticateDevice);

  logger.info(
    "LumaRush Nakama module loaded. Leaderboard ID: %s",
    MODULE_CONFIG.leaderboardId
  );
}

function loadConfig(ctx) {
  var env = (ctx && ctx.env) || {};

  var timeout = toInt(env.TPX_HTTP_TIMEOUT_MS, 5000);
  if (timeout <= 0) {
    timeout = 5000;
  }

  return {
    leaderboardId: env.LUMARUSH_LEADERBOARD_ID || DEFAULT_LEADERBOARD_ID,
    authUrl: env.TPX_PLATFORM_AUTH_URL || "",
    eventUrl: env.TPX_PLATFORM_EVENT_URL || "",
    apiKey: env.TPX_PLATFORM_API_KEY || "",
    httpTimeoutMs: timeout,
  };
}

function ensureLeaderboard(nk, logger, leaderboardId) {
  try {
    nk.leaderboardCreate(
      leaderboardId,
      true,
      "descending",
      "best",
      null,
      { game: "LumaRush", platform: "terapixel" },
      true
    );
    logger.info("Created leaderboard %s", leaderboardId);
  } catch (err) {
    logger.info(
      "Leaderboard %s already exists or could not be created: %s",
      leaderboardId,
      err
    );
  }
}

function beforeAuthenticateCustom(ctx, logger, nk, request) {
  var externalId = request && request.account ? request.account.id || "" : "";
  verifyPlatformAuth(nk, logger, "custom", externalId, request.username || "");
  return request;
}

function beforeAuthenticateDevice(ctx, logger, nk, request) {
  var externalId = request && request.account ? request.account.id || "" : "";
  verifyPlatformAuth(nk, logger, "device", externalId, request.username || "");
  return request;
}

function afterAuthenticateCustom(ctx, logger, nk, session, request) {
  publishPlatformEvent(
    nk,
    logger,
    "auth_success",
    {
      provider: "custom",
      externalId: request && request.account ? request.account.id || "" : "",
      username: request && request.username ? request.username : "",
      created: session && session.created ? true : false,
    },
    ctx
  );
}

function afterAuthenticateDevice(ctx, logger, nk, session, request) {
  publishPlatformEvent(
    nk,
    logger,
    "auth_success",
    {
      provider: "device",
      externalId: request && request.account ? request.account.id || "" : "",
      username: request && request.username ? request.username : "",
      created: session && session.created ? true : false,
    },
    ctx
  );
}

function verifyPlatformAuth(nk, logger, provider, externalId, username) {
  if (!MODULE_CONFIG.authUrl) {
    return;
  }

  var headers = { "Content-Type": "application/json" };
  if (MODULE_CONFIG.apiKey) {
    headers.Authorization = "Bearer " + MODULE_CONFIG.apiKey;
  }

  var body = JSON.stringify({
    provider: provider,
    externalId: externalId,
    username: username,
    source: "lumarush-nakama",
  });

  var response = nk.httpRequest(
    MODULE_CONFIG.authUrl,
    "post",
    headers,
    body,
    MODULE_CONFIG.httpTimeoutMs,
    false
  );

  if (response.code < 200 || response.code >= 300) {
    logger.warn(
      "Platform auth verification rejected (%s) for provider=%s externalId=%s",
      response.code,
      provider,
      externalId
    );
    throw new Error("Authentication rejected by Terapixel platform.");
  }
}

function rpcSubmitScore(ctx, logger, nk, payload) {
  assertAuthenticated(ctx);

  var data = parsePayload(payload);
  var score = toInt(data.score, NaN);
  if (!isFinite(score) || score < 0) {
    throw new Error("score must be a non-negative integer");
  }

  var subscore = data.subscore === undefined ? 0 : toInt(data.subscore, NaN);
  if (!isFinite(subscore) || subscore < 0) {
    throw new Error("subscore must be a non-negative integer");
  }

  var metadata = data.metadata;
  if (!metadata || typeof metadata !== "object" || Array.isArray(metadata)) {
    metadata = {};
  }

  var record = nk.leaderboardRecordWrite(
    MODULE_CONFIG.leaderboardId,
    ctx.userId,
    ctx.username || "",
    score,
    subscore,
    metadata,
    "best"
  );

  writePlayerHighScore(nk, ctx.userId, record);

  publishPlatformEvent(
    nk,
    logger,
    "score_submitted",
    {
      leaderboardId: MODULE_CONFIG.leaderboardId,
      score: record.score,
      subscore: record.subscore,
      rank: record.rank,
      metadata: metadata,
    },
    ctx
  );

  return JSON.stringify({
    leaderboardId: MODULE_CONFIG.leaderboardId,
    record: record,
  });
}

function rpcGetMyHighScore(ctx, logger, nk, payload) {
  assertAuthenticated(ctx);

  var records = nk.leaderboardRecordsList(
    MODULE_CONFIG.leaderboardId,
    [ctx.userId],
    1
  );
  var ownerRecord = null;
  if (records.ownerRecords && records.ownerRecords.length > 0) {
    ownerRecord = records.ownerRecords[0];
  } else if (records.records && records.records.length > 0) {
    ownerRecord = records.records[0];
  }

  var storage = nk.storageRead([
    {
      collection: PLAYER_STATS_COLLECTION,
      key: PLAYER_STATS_KEY,
      userId: ctx.userId,
    },
  ]);

  return JSON.stringify({
    leaderboardId: MODULE_CONFIG.leaderboardId,
    highScore: ownerRecord,
    playerStats:
      storage && storage.length > 0 && storage[0].value ? storage[0].value : {},
  });
}

function rpcListLeaderboard(ctx, logger, nk, payload) {
  var data = parsePayload(payload);
  var limit = toInt(data.limit, 25);
  if (!isFinite(limit) || limit <= 0) {
    limit = 25;
  }
  if (limit > 100) {
    limit = 100;
  }

  var cursor =
    typeof data.cursor === "string" && data.cursor.length > 0
      ? data.cursor
      : undefined;

  var list = nk.leaderboardRecordsList(
    MODULE_CONFIG.leaderboardId,
    undefined,
    limit,
    cursor
  );

  return JSON.stringify({
    leaderboardId: MODULE_CONFIG.leaderboardId,
    records: list.records || [],
    nextCursor: list.nextCursor || "",
    prevCursor: list.prevCursor || "",
    rankCount: list.rankCount || 0,
  });
}

function writePlayerHighScore(nk, userId, record) {
  nk.storageWrite([
    {
      collection: PLAYER_STATS_COLLECTION,
      key: PLAYER_STATS_KEY,
      userId: userId,
      value: {
        bestScore: record.score,
        bestSubscore: record.subscore,
        rank: record.rank,
        leaderboardId: record.leaderboardId,
        updatedAt: record.updateTime,
      },
      permissionRead: 1,
      permissionWrite: 0,
    },
  ]);
}

function publishPlatformEvent(nk, logger, eventType, payload, ctx) {
  if (!MODULE_CONFIG.eventUrl) {
    return;
  }

  var headers = { "Content-Type": "application/json" };
  if (MODULE_CONFIG.apiKey) {
    headers.Authorization = "Bearer " + MODULE_CONFIG.apiKey;
  }

  var body = JSON.stringify({
    eventType: eventType,
    source: "lumarush-nakama",
    occurredAtUnix: Math.floor(Date.now() / 1000),
    userId: ctx && ctx.userId ? ctx.userId : "",
    username: ctx && ctx.username ? ctx.username : "",
    payload: payload,
  });

  try {
    var response = nk.httpRequest(
      MODULE_CONFIG.eventUrl,
      "post",
      headers,
      body,
      MODULE_CONFIG.httpTimeoutMs,
      false
    );
    if (response.code < 200 || response.code >= 300) {
      logger.warn(
        "Platform event not accepted. code=%s eventType=%s",
        response.code,
        eventType
      );
    }
  } catch (err) {
    logger.warn("Platform event publish failed. eventType=%s err=%s", eventType, err);
  }
}

function assertAuthenticated(ctx) {
  if (!ctx || !ctx.userId) {
    throw new Error("User session is required.");
  }
}

function parsePayload(payload) {
  if (!payload) {
    return {};
  }
  try {
    var parsed = JSON.parse(payload);
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
      throw new Error("payload must be a JSON object");
    }
    return parsed;
  } catch (err) {
    throw new Error("invalid JSON payload");
  }
}

function toInt(value, fallback) {
  if (value === null || value === undefined || value === "") {
    return fallback;
  }
  var parsed = Number(value);
  if (!isFinite(parsed)) {
    return fallback;
  }
  return Math.floor(parsed);
}
