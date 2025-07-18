#!/usr/bin/env node

var debug = require("debug");
var debugLog = debug("kreptoexp:config");

// to debug arg settings, enable the below line:
//debug.enable("kreptoexp:*");

const args = require('meow')(`
	Usage
	  $ krepto-rpc-explorer [options]

	Options
	  -p, --port <port>			  port to bind http server [default: 3002]
	  -i, --host <host>			  host to bind http server [default: 127.0.0.1]
	  -a, --basic-auth-password <..> protect web interface with a password [default: no password]
	  -C, --coin <coin>			  crypto-coin to enable [default: KREPTO]

	  -b, --kreptod-uri <uri>	   connection URI for kreptod rpc (overrides the options below)
	  -H, --kreptod-host <host>	 hostname for kreptod rpc [default: 127.0.0.1]
	  -P, --kreptod-port <port>	 port for kreptod rpc [default: 8332]
	  -c, --kreptod-cookie <path>   path to kreptod cookie file [default: ~/.krepto/.cookie]
	  -u, --kreptod-user <user>	 username for kreptod rpc [default: none]
	  -w, --kreptod-pass <pass>	 password for kreptod rpc [default: none]

	  --address-api <option>		 api to use for address queries (options: electrum, blockchain.com, blockchair.com, blockcypher.com) [default: none]
	  -E, --electrum-servers <..>   comma separated list of electrum servers to use for address queries; only used if --address-api=electrum [default: none]

	  --rpc-allowall				 allow all rpc commands [default: false]
	  --rpc-blacklist <methods>	  comma separated list of rpc commands to block [default: see in config.js]
	  --cookie-secret <secret>	   secret key for signed cookie hmac generation [default: hmac derive from kreptod pass]
	  --demo						 enable demoSite mode [default: disabled]
	  --no-rates					 disable fetching of currency exchange rates [default: enabled]
	  --slow-device-mode			 disable performance-intensive tasks (e.g. UTXO set fetching) [default: enabled]
	  --privacy-mode				 enable privacyMode to disable external data requests [default: disabled]
	  --max-mem <bytes>			  value for max_old_space_size [default: 1024 (1 GB)]

	  --ganalytics-tracking <tid>	tracking id for google analytics [default: disabled]
	  --sentry-url <sentry-url>	  sentry url [default: disabled]

	  -e, --node-env <env>		   nodejs environment mode [default: production]
	  -h, --help					 output usage information
	  -v, --version				  output version number

	Examples
	  $ krepto-rpc-explorer --port 8080 --kreptod-port 18443 --kreptod-cookie ~/.krepto/regtest/.cookie
	  $ krepto-rpc-explorer -p 8080 -P 18443 -c ~/.krepto/regtest.cookie

	Or using connection URIs
	  $ krepto-rpc-explorer -b krepto://bob:myPassword@127.0.0.1:18443/
	  $ krepto-rpc-explorer -b krepto://127.0.0.1:18443/?cookie=$HOME/.krepto/regtest/.cookie

	All options may also be specified as environment variables
	  $ KREPTOEXP_PORT=8080 KREPTOEXP_KREPTOD_PORT=18443 KREPTOEXP_KREPTOD_COOKIE=~/.krepto/regtest/.cookie krepto-rpc-explorer


`, {
		flags: {
			port: {alias:'p'},
			host: {alias:'i'},
			basicAuthPassword: {alias:'a'},
			coin: {alias:'C'},
			kreptodUri: {alias:'b'},
			kreptodHost: {alias:'H'},
			kreptodPort: {alias:'P'},
			kreptodCookie: {alias:'c'},
			kreptodUser: {alias:'u'},
			kreptodPass: {alias:'w'},
			demo: {},
			rpcAllowall: {},
			electrumServers: {alias:'E'},
			nodeEnv: {alias:'e', default:'production'},
			privacyMode: {},
			slowDeviceMode: {}
		}
	}
).flags;

const envify = k => k.replace(/([A-Z])/g, '_$1').toUpperCase();

Object.keys(args).filter(k => k.length > 1).forEach(k => {
	if (args[k] === false) {
		debugLog(`Config(arg): KREPTOEXP_NO_${envify(k)}=true`);

		process.env[`KREPTOEXP_NO_${envify(k)}`] = true;

	} else {
		debugLog(`Config(arg): KREPTOEXP_${envify(k)}=${args[k]}`);

		process.env[`KREPTOEXP_${envify(k)}`] = args[k];
	}
});

require('./www');
