FROM google/dart-runtime
RUN pub build
ADD . /app/