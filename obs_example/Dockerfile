FROM opensuse:latest 

# Make obs_install available
ADD obs_install /usr/bin/obs_install

RUN obs_install util-linux calcurse
RUN obs_install awk gcc \
  which

RUN ls # irrelevant command before additional dependencies

RUN obs_install glibc \  
  file-magic && ls ; ls -la ; obs_install nethogs

RUN obs_install ssh-contact; ls && ls -la
