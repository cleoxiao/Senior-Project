# -*- coding: utf-8 -*-
# @File    : settings.py
# @Author  : CleoXiao
# @Time    : 04/26/2021
# @Reference/Cite: @misc{bert4keras,
#   title={bert4keras},
#   author={Jianlin Su},
#   year={2020},
#   howpublished={\url{https://bert4keras.spaces.ac.cn}},
# }
# @Reference: https://www.aaronjny.com/articles/2020/03/11/1583923113887.html


# 预训练的模型参数
CONFIG_PATH = './chinese_L-12_H-768_A-12/bert_config.json'
CHECKPOINT_PATH = './chinese_L-12_H-768_A-12/bert_model.meta.ckpt'
DICT_PATH = './chinese_L-12_H-768_A-12/vocab.txt'
# 禁用词，包含如下字符的唐诗将被忽略
DISALLOWED_WORDS = ['（', '）', '(', ')', '__', '《', '》', '【', '】', '[', ']']
# 句子最大长度
MAX_LEN = 64
# 最小词频
MIN_WORD_FREQUENCY = 8
# 训练的batch size
BATCH_SIZE = 32
# 数据集路径
DATASET_PATH = './poetry.txt'
# 每个epoch训练完成后，随机生成SHOW_NUM首古诗作为展示
SHOW_NUM = 5
# 共训练多少个epoch
TRAIN_EPOCHS = 20
# 最佳权重保存路径
BEST_MODEL_PATH = './best_model.weights'
