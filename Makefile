deploy:
	cd webapp/go; \
	GOOS=linux GOARCH=amd64 go build -o bin-isuports cmd/isuports/main.go; \
	scp bin-isuports isucon12-qualify-retry-1:/home/isucon/webapp/go/ \
	ssh isucon12-qualify-retry-1 "sudo systemctl restart isuports.service"

build:
	ssh isucon12-qualify-retry-1 "sudo systemctl restart isuports.service"

mysql-deploy:
	ssh isucon12-qualify-retry-1 "sudo dd of=/etc/mysql/mysql.conf.d/mysqld.cnf" < ./etc/mysql/mysql.conf.d/mysqld.cnf

mysql-rotate:
	ssh isucon12-qualify-retry-1 "sudo rm -f /var/log/mysql/mysql-slow.log"

mysql-restart:
	ssh isucon12-qualify-retry-1 "sudo systemctl restart mysql.service"

nginx-rotate:
	ssh isucon12-qualify-retry-1 "sudo rm -f /var/log/nginx/access.log"

nginx-reload:
	ssh isucon12-qualify-retry-1 "sudo systemctl reload nginx.service"

nginx-restart:
	ssh isucon12-qualify-retry-1 "sudo systemctl restart nginx.service"

#bench-run:
#	ssh isucon12-qualify-retry-1 " \
#		cd /home/isucon/benchmarker; \
#		./bin/benchmarker -target localhost:443 -tls"

pt-query-digest:
	ssh isucon12-qualify-retry-1 "sudo pt-query-digest --limit 10 /var/log/mysql/mysql-slow.log"

ALPSORT=sum
# /api/player/competition/[0-9a-z]+/ranking
# /api/player/player/[0-9a-z]+
# /api/organizer/competition/[0-9a-z]+/finish
# /api/organizer/competition/[0-9a-z]+/score
# /api/organizer/player/[0-9a-z]+/disqualified
# /api/admin/tenants/billing
ALPM=/api/player/competition/[0-9a-z]+/ranking,/api/player/player/[0-9a-z]+,/api/organizer/competition/[0-9a-z]+/finish,/api/organizer/competition/[0-9a-z]+/score,/api/organizer/player/[0-9a-z]+/disqualified,/api/admin/tenants/billing
OUTFORMAT=count,method,uri,min,max,sum,avg,p99

alp:
	ssh isucon12-qualify-retry-1 "sudo alp ltsv --file=/var/log/nginx/access.log --nosave-pos --pos /tmp/alp.pos --sort $(ALPSORT) --reverse -o $(OUTFORMAT) -m $(ALPM) -q"

bench-run:
	ssh isucon12-qualify-retry-1 " \
	cd /home/isucon/bench; \
	./bench"

.PHONY: pprof
pprof: pprof-build pprof-request
pprof-build:
	ssh isucon12-qualify-retry-1 " \
		cd /home/isucon/webapp/go/cmd/isuports; \
		rm -f pprof-isuports; \
		/usr/local/go/bin/go build -o pprof-isuports"
pprof-request:
	sleep 1; \
	ssh isucon12-qualify-retry-1 " \
		/usr/local/go/bin/go tool pprof -seconds=75 /home/isucon/webapp/go/cmd/isuports/pprof-isuports http://localhost:6060/debug/pprof/profile"

pprof-kill:
	ssh isucon12-qualify-retry-1 "pgrep -f 'pprof' | xargs kill;"

pprof-show:
	$(eval latest := $(shell ssh isucon12-qualify-retry-1 "ls -rt ~/pprof/ | tail -n 1"))
	scp isucon12-qualify-retry-1:~/pprof/$(latest) ./pprof
	go tool pprof -http=":1080" ./pprof/$(latest)

