"use strict";

const os = require('os');
const path = require('path');
const url = require('url');
const fs = require("fs");

const debug = require("debug");
const debugLog = debug("kreptoexp:config");

const kreptoUri = process.env.KREPTOEXP_KREPTOD_URI ? url.parse(process.env.KREPTOEXP_KREPTOD_URI, true) : { query: { } };
const kreptoAuth = kreptoUri.auth ? kreptoUri.auth.split(':') : [];




function loadFreshRpcCredentials() {
	let username = kreptoAuth[0] || process.env.KREPTOEXP_KREPTOD_USER;
	let password = kreptoAuth[1] || process.env.KREPTOEXP_KREPTOD_PASS;

	let authCookieFilepath = kreptoUri.query.cookie || process.env.KREPTOEXP_KREPTOD_COOKIE || path.join(os.homedir(), '.krepto', '.cookie');

	let authType = "usernamePassword";

	if (!username && !password && fs.existsSync(authCookieFilepath)) {
		authType = "cookie";
	}

	if (authType == "cookie") {
		debugLog(`Loading RPC cookie file: ${authCookieFilepath}`);
		
		[ username, password ] = fs.readFileSync(authCookieFilepath).toString().trim().split(':', 2);
		
		if (!password) {
			throw new Error(`Cookie file ${authCookieFilepath} in unexpected format`);
		}
	}

	return {
		host: kreptoUri.hostname || process.env.KREPTOEXP_KREPTOD_HOST || "127.0.0.1",
		port: kreptoUri.port || process.env.KREPTOEXP_KREPTOD_PORT || 8332,

		authType: authType,

		username: username,
		password: password,
		
		authCookieFilepath: authCookieFilepath,
		
		timeout: parseInt(kreptoUri.query.timeout || process.env.KREPTOEXP_KREPTOD_RPC_TIMEOUT || 5000),
	};
}

module.exports = {
	loadFreshRpcCredentials: loadFreshRpcCredentials,

	rpc: loadFreshRpcCredentials(),

	// optional: enter your api access key from ipstack.com below
	// to include a map of the estimated locations of your node's
	// peers
	// format: "ID_FROM_IPSTACK"
	ipStackComApiAccessKey: process.env.KREPTOEXP_IPSTACK_APIKEY,

	// optional: enter your api access key from mapbox.com below
	// to enable the tiles for map of the estimated locations of
	// your node's peers
	// format: "APIKEY_FROM_MAPBOX"
	mapBoxComApiAccessKey: process.env.KREPTOEXP_MAPBOX_APIKEY,

	// optional: GA tracking code
	// format: "UA-..."
	googleAnalyticsTrackingId: process.env.KREPTOEXP_GANALYTICS_TRACKING,

	// optional: sentry.io error-tracking url
	// format: "SENTRY_IO_URL"
	sentryUrl: process.env.KREPTOEXP_SENTRY_URL,
};
