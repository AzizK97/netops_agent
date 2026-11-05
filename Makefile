CLAB   ?= clab
LAB    := data_center
TOPO   := dc_lab.clab.yml
PREFIX := clab-$(LAB)
NODE   ?= leaf1
OBS_COMPOSE := observability/compose.yml

SPINES := spine1 spine2
LEAVES := leaf1 leaf2 leaf3 leaf4

FRR_EXP_VER  := 1.12.0
NODE_EXP_VER := 1.12.1

.DEFAULT_GOAL := help
.PHONY: help deploy destroy redeploy test all inspect graph bgp routes vtysh shell logs edgeshark-up edgeshark-down clean render diff push exporters targets logdirs

help:
	@echo "make deploy         deploy the lab"
	@echo "make destroy        destroy the lab"
	@echo "make redeploy       deploy --reconfigure"
	@echo "make test           run scripts/reachability.sh"
	@echo "make all            redeploy + test"
	@echo "make inspect        show nodes and IPs"
	@echo "make graph          open the topology graph"
	@echo "make bgp            BGP summary on all spines and leaves"
	@echo "make routes NODE=x  show ip route on a node (default leaf1)"
	@echo "make vtysh NODE=x   open vtysh on a node"
	@echo "make shell NODE=x   open a shell on a node (hosts too)"
	@echo "make logs NODE=x    container logs of a node"
	@echo "make edgeshark-up / edgeshark-down"
	@echo "make clean          destroy + remove lab artifacts"
	@echo "make render         render configs/ from inventory + templates"
	@echo "make diff           render + show diff against running config"
	@echo "make push           render + apply to the routers"
	@echo "make exporters      download exporter binaries into bin/"
	@echo "make targets        generate the targets for Prometheus"
	@echo "make obs-up         bring the observability up"
	@echo "make obs-down       bring the observability  down"
	@echo "make logdirs        creates the log directories for the FRR routers"

deploy: exporters logdirs
	$(CLAB) deploy -t $(TOPO)

destroy:
	$(CLAB) destroy -t $(TOPO)

redeploy: exporters logdirs
	$(CLAB) deploy -t $(TOPO) --reconfigure

test:
	./scripts/reachability.sh

all: redeploy test

inspect:
	$(CLAB) inspect -t $(TOPO)

graph:
	$(CLAB) graph -t $(TOPO)

bgp:
	@for n in $(SPINES) $(LEAVES); do \
		echo "=== $$n ==="; \
		docker exec $(PREFIX)-$$n vtysh -c 'show bgp summary'; \
	done

routes:
	docker exec $(PREFIX)-$(NODE) vtysh -c 'show ip route'

vtysh:
	docker exec -it $(PREFIX)-$(NODE) vtysh

shell:
	docker exec -it $(PREFIX)-$(NODE) sh

logs:
	docker logs $(PREFIX)-$(NODE)

edgeshark-up:
	sudo $(CLAB) tools edgeshark install

edgeshark-down:
	sudo $(CLAB) tools edgeshark uninstall

clean:
	$(CLAB) destroy -t $(TOPO) --cleanup

render: targets
	uv run python render.py

diff: render
	uv run python push.py

push: render
	uv run python push.py --apply

exporters: bin/frr_exporter bin/node_exporter

bin/frr_exporter:
	mkdir -p bin
	curl -sL https://github.com/tynany/frr_exporter/releases/download/v$(FRR_EXP_VER)/frr_exporter-$(FRR_EXP_VER).linux-amd64.tar.gz \
	  | tar xz -C bin --strip-components=1 frr_exporter-$(FRR_EXP_VER).linux-amd64/frr_exporter

bin/node_exporter:
	mkdir -p bin
	curl -sL https://github.com/prometheus/node_exporter/releases/download/v$(NODE_EXP_VER)/node_exporter-$(NODE_EXP_VER).linux-amd64.tar.gz \
	  | tar xz -C bin --strip-components=1 node_exporter-$(NODE_EXP_VER).linux-amd64/node_exporter

targets:
	uv run python render_targets.py

obs-up: targets
	docker compose -f $(OBS_COMPOSE) up -d

obs-down:
	docker compose -f $(OBS_COMPOSE) down

logdirs:
	mkdir -p $(addprefix logs/,$(SPINES) $(LEAVES))
	chmod 777 logs/*        # FRR runs as uid 100 inside the container (lab only)
