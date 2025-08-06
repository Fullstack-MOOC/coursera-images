FROM --platform=linux/amd64 cypress/base:22.12.0

WORKDIR /grader

RUN apt-get update && apt-get install -y bc jq curl && rm -rf /var/lib/apt/lists/*
RUN npm install -g cypress@13.17.0
RUN npx cypress install
RUN npx cypress verify

COPY grader.sh ./
RUN chmod +x grader.sh

ENTRYPOINT ["./grader.sh"]