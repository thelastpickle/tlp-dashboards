FROM  sparkprime/jsonnet

# Ideally get back to https://github.com/grafana/grafonnet-lib.git when our PRs are merged
# When doing so use a specific tag (if any) or commit.
RUN apk update && apk add git && git clone https://github.com/grafana/grafonnet-lib.git && \
    cd grafonnet-lib && git checkout 906768d46973e022594d3f03d82c5a51d86de2cc && \
    git clone https://github.com/thelastpickle/grafonnet-polystat-panel.git && git checkout master

COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

ENTRYPOINT /entrypoint.sh
