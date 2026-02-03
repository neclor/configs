server {
	listen 443 ssl http2 default_server;
	listen [::]:443 ssl http2 default_server;

	server_name *.neclor.com;

	include snippets/ssl-neclor.com.conf;

	return 404;
}
