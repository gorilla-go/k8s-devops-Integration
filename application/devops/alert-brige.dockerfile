FROM alpine:3.19.1

COPY ./alert-brige/alert-brige /bin/alert-brige

CMD ["alert-brige"]