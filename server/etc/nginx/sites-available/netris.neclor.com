server {
	listen 443 ssl http2;
	listen [::]:443 ssl http2;

	include snippets/ssl-neclor.com.conf;

	server_name netris.neclor.com www.netris.neclor.com;

	root /srv/www/netris.neclor.com;
	index index.html index.htm;

	location /Leaderboard {
		proxy_pass http://127.0.0.1:5220;
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection keep-alive;
		proxy_set_header Host $host;
		proxy_cache_bypass $http_upgrade;
	}

	location / {
		try_files $uri $uri/ =404;
	}

	add_header X-Frame-Options SAMEORIGIN always;
	add_header X-Content-Type-Options nosniff always;
	add_header Referrer-Policy no-referrer always;

	add_header Cross-Origin-Embedder-Policy "require-corp";
	add_header Cross-Origin-Opener-Policy "same-origin";

	gzip on;
	gzip_types application/wasm text/css text/javascript application/javascript;
}
