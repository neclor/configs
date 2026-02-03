server {
	listen 443 ssl http2;
	listen [::]:443 ssl http2;

	include snippets/ssl-neclor.com.conf;

	server_name gateway.neclor.com;

	root /var/www/html;
	index index.html index.htm;

	location /h2 {
		proxy_pass http://127.0.0.1:10443;
		proxy_http_version 1.1;

		proxy_set_header Host $host;

		proxy_set_header X-Forwarded-For $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

		proxy_read_timeout 5d;
	}
}
