"use strict";

const debug = require("debug");
const debugLog = debug("kreptoexp:config");

const fs = require('fs');
const crypto = require('crypto');
const url = require('url');
const path = require('path');

const apiDocs = require("../docs/api.js");

let baseUrl = (process.env.KREPTOEXP_BASEURL || "/").trim();
if (!baseUrl.startsWith("/")) {
	baseUrl = "/" + baseUrl;
}
if (!baseUrl.endsWith("/")) {
	baseUrl += "/";
}


let cdnBaseUrl = (process.env.KREPTOEXP_CDN_BASE_URL || ".").trim();
while (cdnBaseUrl.endsWith("/")) {
	cdnBaseUrl = cdnBaseUrl.substring(0, cdnBaseUrl.length - 1);
}

let s3BucketPath = (process.env.KREPTOEXP_S3_BUCKET_PATH || "").trim();
while (s3BucketPath.endsWith("/")) {
	s3BucketPath = s3BucketPath.substring(0, s3BucketPath.length - 1);
}


const coins = require("./coins.js");
const credentials = require("./credentials.js");

const currentCoin = process.env.KREPTOEXP_COIN || "KREPTO";

const rpcCred = credentials.rpc;


const cookieSecret = process.env.KREPTOEXP_COOKIE_SECRET
 || (rpcCred.password && crypto.createHmac('sha256', JSON.stringify(rpcCred))
                               .update('krepto-rpc-explorer-cookie-secret').digest('hex'))
 || "0x000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f";


const electrumServerUriStrings = (process.env.KREPTOEXP_ELECTRUM_SERVERS || process.env.KREPTOEXP_ELECTRUMX_SERVERS || "").split(',').filter(Boolean);
const electrumServers = [];
for (let i = 0; i < electrumServerUriStrings.length; i++) {
	const uri = url.parse(electrumServerUriStrings[i]);
	
	electrumServers.push({protocol:uri.protocol.substring(0, uri.protocol.length - 1), host:uri.hostname, port:parseInt(uri.port)});
}

// default=false env vars
[
	"KREPTOEXP_DEMO",
	"KREPTOEXP_PRIVACY_MODE",
	"KREPTOEXP_NO_INMEMORY_RPC_CACHE",
	"KREPTOEXP_RPC_ALLOWALL",
	"KREPTOEXP_ELECTRUM_TXINDEX",
	"KREPTOEXP_UI_HIDE_INFO_NOTES",

].forEach(function(item) {
	if (process.env[item] === undefined) {
		process.env[item] = "false";

		debugLog(`Config(default): ${item}=false`)
	}
});


// default=true env vars
[
	"KREPTOEXP_NO_RATES",
	"KREPTOEXP_SLOW_DEVICE_MODE"

].forEach(function(item) {
	if (process.env[item] === undefined) {
		process.env[item] = "true";

		debugLog(`Config(default): ${item}=true`)
	}
});

const slowDeviceMode = (process.env.KREPTOEXP_SLOW_DEVICE_MODE.toLowerCase() == "true");

module.exports = {
	host: process.env.KREPTOEXP_HOST || "127.0.0.1",
	port: process.env.PORT || process.env.KREPTOEXP_PORT || 3002,
	secureSite: process.env.KREPTOEXP_SECURE_SITE == "true",

	baseUrl: baseUrl,
	apiBaseUrl: apiDocs.baseUrl,

	coin: currentCoin,

	displayDefaults: {
		displayCurrency: (process.env.KREPTOEXP_DISPLAY_CURRENCY || "krepto"),
		localCurrency: (process.env.KREPTOEXP_LOCAL_CURRENCY || "usd"),
		theme: (process.env.KREPTOEXP_UI_THEME || "dark"),
		timezone: (process.env.KREPTOEXP_UI_TIMEZONE || "local")
	},

	cookieSecret: cookieSecret,

	privacyMode: (process.env.KREPTOEXP_PRIVACY_MODE.toLowerCase() == "true"),
	slowDeviceMode: slowDeviceMode,
	demoSite: (process.env.KREPTOEXP_DEMO.toLowerCase() == "true"),
	queryExchangeRates: (process.env.KREPTOEXP_NO_RATES.toLowerCase() != "true" && process.env.KREPTOEXP_PRIVACY_MODE.toLowerCase() != "true"),
	noInmemoryRpcCache: (process.env.KREPTOEXP_NO_INMEMORY_RPC_CACHE.toLowerCase() == "true"),
	
	rpcConcurrency: (process.env.KREPTOEXP_RPC_CONCURRENCY || (slowDeviceMode ? 3 : 10)),

	filesystemCacheDir: (process.env.KREPTOEXP_FILESYSTEM_CACHE_DIR || path.join(process.cwd(),"./cache")),

	noTxIndexSearchDepth: (+process.env.KREPTOEXP_NOTXINDEX_SEARCH_DEPTH || 3),

	cdn: {
		active: (cdnBaseUrl == "." ? false : true),
		s3Bucket: process.env.KREPTOEXP_S3_BUCKET,
		s3BucketRegion: process.env.KREPTOEXP_S3_BUCKET_REGION,
		s3BucketPath: s3BucketPath,
		baseUrl: cdnBaseUrl
	},

	rateLimiting: {
		windowMinutes: process.env.KREPTOEXP_RATE_LIMIT_WINDOW_MINUTES || 15,
		windowMaxRequests: process.env.KREPTOEXP_RATE_LIMIT_WINDOW_MAX_REQUESTS || 200
	},

	rpcBlacklist:
		process.env.KREPTOEXP_RPC_ALLOWALL.toLowerCase() == "true"  ? []
		: process.env.KREPTOEXP_RPC_BLACKLIST ? process.env.KREPTOEXP_RPC_BLACKLIST.split(',').filter(Boolean)
		: [
		"addnode",
		"backupwallet",
		"bumpfee",
		"clearbanned",
		"createmultisig",
		"createwallet",
		"disconnectnode",
		"dumpprivkey",
		"dumpwallet",
		"encryptwallet",
		"generate",
		"generatetoaddress",
		"getaccountaddrss",
		"getaddressesbyaccount",
		"getbalance",
		"getnewaddress",
		"getrawchangeaddress",
		"getreceivedbyaccount",
		"getreceivedbyaddress",
		"gettransaction",
		"getunconfirmedbalance",
		"getwalletinfo",
		"importaddress",
		"importmulti",
		"importprivkey",
		"importprunedfunds",
		"importpubkey",
		"importwallet",
		"invalidateblock",
		"keypoolrefill",
		"listaccounts",
		"listaddressgroupings",
		"listlockunspent",
		"listreceivedbyaccount",
		"listreceivedbyaddress",
		"listsinceblock",
		"listtransactions",
		"listunspent",
		"listwallets",
		"lockunspent",
		"logging",
		"move",
		"preciousblock",
		"pruneblockchain",
		"reconsiderblock",
		"removeprunedfunds",
		"rescanblockchain",
		"savemempool",
		"sendfrom",
		"sendmany",
		"sendtoaddress",
		"setaccount",
		"setban",
		"setmocktime",
		"setnetworkactive",
		"signmessage",
		"signmessagewithprivatekey",
		"signrawtransaction",
		"signrawtransactionwithkey",
		"stop",
		"submitblock",
		"syncwithvalidationinterfacequeue",
		"verifychain",
		"waitforblock",
		"waitforblockheight",
		"waitfornewblock",
		"walletlock",
		"walletpassphrase",
		"walletpassphrasechange",
	],

	addressApi: process.env.KREPTOEXP_ADDRESS_API,
	electrumTxIndex: process.env.KREPTOEXP_ELECTRUM_TXINDEX != "false",
	electrumServers: electrumServers,

	redisUrl:process.env.KREPTOEXP_REDIS_URL,

	site: {
		hideInfoNotes: process.env.KREPTOEXP_UI_HIDE_INFO_NOTES,
		homepage:{
			recentBlocksCount: parseInt(process.env.KREPTOEXP_UI_HOME_PAGE_LATEST_BLOCKS_COUNT || (slowDeviceMode ? 5 : 10))
		},
		blockTxPageSize: (slowDeviceMode ? 10 : 20),
		addressTxPageSize: 10,
		txMaxInput: (slowDeviceMode ? 3 : 15),
		browseBlocksPageSize: parseInt(process.env.KREPTOEXP_UI_BLOCKS_PAGE_BLOCK_COUNT || (slowDeviceMode ? 10 : 25)),
		browseMempoolTransactionsPageSize: (slowDeviceMode ? 10 : 25),
		addressPage:{
			txOutputMaxDefaultDisplay:10
		},
		valueDisplayMaxLargeDigits: 4,
		prioritizedToolIdsList: [0, 10, 11, 9, 3, 4, 16, 12, 2, 5, 15, 1, 13, 17],
		toolSections: [
			{name: "Basics", items: [0, 2]},
			{name: "Mempool", items: [4, 16, 5]},
			{name: "Analysis", items: [9, 18, 10, 11, 12, 3, 20]},
			{name: "Technical", items: [15, 1]},
			{name: "Fun", items: [17, 13]},
		]
	},

	credentials: credentials,

	siteTools:[
	/* 0 */		{name:"Node Details", url:"./node-details", desc:"Node basics (version, uptime, etc)", iconClass:"bi-info-circle"},
	/* 1 */		{name:"Peers", url:"./peers", desc:"Details about the peers connected to this node.", iconClass:"bi-diagram-3"},
	/* 2 */		{name:"Browse Blocks", url:"./blocks", desc:"Browse all blocks in the blockchain.", iconClass:"bi-boxes"},
	/* 3 */		{name:"Transaction Stats", url:"./tx-stats", desc:"See graphs of total transaction volume and transaction rates.", iconClass:"bi-graph-up"},
	/* 4 */		{name:"Mempool Summary", url:"./mempool-summary", desc:"Detailed summary of the current mempool for this node.", iconClass:"bi-hourglass-split"},
	/* 5 */		{name:"Browse Mempool", url:"./mempool-transactions", desc:"Browse unconfirmed/pending transactions.", iconClass:"bi-book"},
	/* 6 */		null, // Removed: RPC Browser
	/* 7 */		null, // Removed: RPC Terminal
	/* 8 */		null, // Removed: Fun section was commented out
	/* 9 */		{name:"Mining Summary", url:"./mining-summary", desc:"Summary of recent data about miners.", iconClass:"bi-hammer"},
	/* 10 */	{name:"Block Stats", url:"./block-stats", desc:"Summary data for blocks in configurable range.", iconClass:"bi-stack"},
	/* 11 */	{name:"Block Analysis", url:"./block-analysis", desc:"Summary analysis for all transactions in a block.", iconClass:"bi-chevron-double-down"},
	/* 12 */	{name:"Difficulty History", url:"./difficulty-history", desc:"Details of difficulty changes over time.", iconClass:"bi-clock-history"},
	/* 13 */	{name:"Whitepaper Extractor", url:"./krepto-whitepaper", desc:"Extract the Krepto whitepaper from data embedded within the blockchain.", iconClass:"bi-file-earmark-text"},
	/* 14 */	{name:"Predicted Blocks", url:"./predicted-blocks", desc:"View predicted future blocks based on the current mempool.", iconClass:"bi-arrow-right-circle"},
	/* 15 */	{name:"API", url:`.${apiDocs.baseUrl}/docs`, desc:"View docs for the public API.", iconClass:"bi-braces-asterisk"},
	/* 16 */	{name:"Next Block", url:"./next-block", desc:"View a prediction for the next block, based on the current mempool.", iconClass:"bi-minecart-loaded"},
	/* 17 */	{name:"Quotes", url:"./quotes", desc:"Curated list of Krepto-related quotes.", iconClass:"bi-chat-quote"},
	/* 18 */	{name:"UTXO Set", url:"./utxo-set", desc:"View the latest UTXO Set.", iconClass:"bi-list-columns"},
	/* 19 */	null, // Removed: Holidays section was commented out
	/* 20 */	{name:"Next Halving", url:"./next-halving", desc:"Estimated details about the next halving.", iconClass:"bi-square-half"},
	]
};

debugLog(`Config(final): privacyMode=${module.exports.privacyMode}`);
debugLog(`Config(final): slowDeviceMode=${module.exports.slowDeviceMode}`);
debugLog(`Config(final): demo=${module.exports.demoSite}`);
debugLog(`Config(final): rpcAllowAll=${module.exports.rpcBlacklist.length == 0}`);
