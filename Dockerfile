FROM rayproject/ray-ml:latest

RUN sudo apt-get update -y \
    && sudo apt-get install -y openjdk-8-jdk \
    && sudo apt-get clean

ENV RAY_memory_monitor_refresh_ms 0

RUN $HOME/anaconda3/bin/pip --no-cache-dir --user install data_process

# RUN $HOME/anaconda3/bin/pip --no-cache-dir install raydp --user