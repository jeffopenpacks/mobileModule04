import * as functions from "firebase-functions";
import fetch from "node-fetch";

export const githubAuth = functions.https.onRequest(async (req, res) => {
  const code = req.query.code as string | undefined;
  if (!code) {
    res.status(400).json({error: "Missing code"});
    return;
  }

  type RuntimeConfig = {
    github: {
      client_id: string;
      client_secret: string;
    };
  };

  const config = (functions as unknown as {config: () => RuntimeConfig})
    .config();
  const clientId = config.github.client_id;
  const clientSecret = config.github.client_secret;

  try {
    const tokenResponse = await fetch("https://github.com/login/oauth/access_token", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: JSON.stringify({
        client_id: clientId,
        client_secret: clientSecret,
        code,
      }),
    });

    const tokenJson = await tokenResponse.json();
    if (!tokenJson.access_token) {
      res.status(400).json(tokenJson);
      return;
    }

    res.json({access_token: tokenJson.access_token});
  } catch (e) {
    res.status(500).json({error: String(e)});
  }
});
