# -*- coding: utf-8 -*-
# @File    : eval.py
# @Author  : CleoXiao
# @Time    : 04/26/2021
# @Reference/Cite: @misc{bert4keras,
#   title={bert4keras},
#   author={Jianlin Su},
#   year={2020},
#   howpublished={\url{https://bert4keras.spaces.ac.cn}},
# }
# @Reference: https://www.aaronjny.com/articles/2020/03/11/1583923113887.html

import tensorflow as tf
from dataset import tokenizer
from translate import translation
import settings
import utils
import os
import sys
import argparse
from pythonosc import udp_client

# parser = argparse.ArgumentParser()
# args = parser.parse_args()
# # args = sys.stdin.reconfigure(encoding='utf-8')
# print(args)

# 随机生成一首诗
#print(utils.generate_random_poetry(tokenizer, model))
# 给出部分信息的情况下，随机生成剩余部分
#print(utils.generate_random_poetry(tokenizer, model, s='床前明月光，'))
# sys.argv[1]


if __name__ == "__main__":
  parser = argparse.ArgumentParser()
  parser.add_argument("--ip", default="127.0.0.1",
      help="The ip of the OSC server")
  parser.add_argument("--port", type=int, default=12000,
      help="The port the OSC server is listening on")
  parser.add_argument("--word", type=str, default="花月",
      help="word for poem") 
  args = parser.parse_args()

  # 加载训练好的模型
model = tf.keras.models.load_model(settings.BEST_MODEL_PATH)
# ----

#   # 生成藏头诗
# print(sys.argv[2])
poetry = utils.generate_acrostic(tokenizer, model, head=sys.argv[2])

trans = translation(poetry)
result = poetry.encode("utf-8")
print(poetry+"\n"+trans)

client = udp_client.SimpleUDPClient(args.ip, args.port)
client.send_message("/filter",result)
#-------

#   for x in range(10):
#     client.send_message("/filter", random.random())
#     time.sleep(1)
