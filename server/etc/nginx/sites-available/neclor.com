server {
	listen 443 ssl http2;
	listen [::]:443 ssl http2;

	include snippets/ssl-neclor.com.conf;

	server_name neclor.com www.neclor.com;

	root /srv/www/neclor.com;
	index index.html index.htm;

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
