.PHONY: docker-image clean

objects = Dockerfile docker-entrypoint.sh haproxy.cfg
docker-tag = jeffre/openfortivpn-haproxy:latest

docker-image: $(objects)
	docker build -t $(docker-tag) .

clean:
	-docker rmi $(docker-tag)
