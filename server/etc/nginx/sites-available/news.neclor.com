server {
	listen 443 ssl http2;
	listen [::]:443 ssl http2;

	include snippets/ssl-neclor.com.conf;

	server_name news.neclor.com www.news.neclor.com;

	root /home/neclor/servers/news-aggregator/src/site/dist;
	index index.html index.htm;

	location /api/ {
		proxy_pass http://localhost:5300/;
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection keep-alive;
		proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
		proxy_cache_bypass $http_upgrade;
	}

	location / {
		try_files $uri $uri/ /index.html;
	}

	add_header X-Frame-Options SAMEORIGIN always;
	add_header X-Content-Type-Options nosniff always;
	add_header Referrer-Policy no-referrer always;

	gzip on;
	gzip_types application/wasm text/css text/javascript application/javascript;
}
