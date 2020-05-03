FROM nginx
RUN useradd -u 1001 webserver
RUN mkdir /app && chown -R webserver:webserver /app/
COPY webserver.conf /etc/nginx/conf.d/webserver.conf
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 8000