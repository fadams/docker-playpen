# The FROM keyword tells Docker which image your image is based on. Whalesay is
# cute and has the cowsay program already, so we’ll start there.

FROM docker/whalesay:latest

# The whalesay image is based on Ubuntu, which uses apt-get to install packages.
# These two commands refresh the list of packages available to the image and
# install the fortunes program into it. The fortunes program prints out wise
# sayings for our whale to say.

RUN apt-get -y update && apt-get install -y fortunes

# Add a CMD statement, which tells the image the final command to run after its
# environment is set up. This command runs fortune -a and sends its output to
# the cowsay command.

CMD /usr/games/fortune -a | cowsay
