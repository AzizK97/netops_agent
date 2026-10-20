CLAB   ?= clab
LAB    := data_center
TOPO   := dc_lab.clab.yml
PREFIX := clab-$(LAB)
NODE   ?= leaf1

SPINES := spine1 spine2
LEAVES := leaf1 leaf2 leaf3 leaf4

.DEFAULT_GOAL := help
.PHONY: help deploy destroy redeploy test all inspect graph bgp routes vtysh shell logs edgeshark-up edgeshark-down clean

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

deploy:
	$(CLAB) deploy -t $(TOPO)

destroy:
	$(CLAB) destroy -t $(TOPO)

redeploy:
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

render:
	uv run python render.py

diff: render
	uv run python push.py

push: render
	uv run python push.py --apply
