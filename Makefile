DOCKERPRE?=lumip-scale-mamba
VOLUMES?=-v $(DOCKERPRE)-programs:/scale-mamba/Programs -v $(DOCKERPRE)-certs:/scale-mamba/Cert-Store -v $(DOCKERPRE)-data:/scale-mamba/Data -v $(DOCKERPRE)-test-data:/scale-mamba/Auto-Test-Data
CONTAINER?=lumip/scale-mamba
TAG?=latest
TEST=

container: Dockerfile
	docker build -t $(CONTAINER):$(TAG) -f Dockerfile .

doc:
	-cd SCALE-MAMBA ; make doc

test:
	./run_docker_tests.sh $(DOCKERPRE) $(CONTAINER):$(TAG) "$(VOLUMES)" $(TEST)

list:
	@echo "container"
	@echo "doc"
	@echo "list"
	@echo "test"
