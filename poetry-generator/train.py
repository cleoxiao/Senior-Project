# -*- coding: utf-8 -*-
# @File    : train.py
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
from dataset import PoetryDataGenerator, tokenizer, poetry
from model import model
import settings
import utils


class Evaluate(tf.keras.callbacks.Callback):
    """
    在每个epoch训练完成后，保留最有权重，并随机生成settings.SHOW_NUM首古诗展示
    """

    def __init__(self):
        super().__init__()
        self.lowest = 1e10

    def on_epoch_end(self, epoch, logs=None):
        if logs['loss'] <= self.lowest:
            self.lowest = logs['loss']
            model.save_weights(settings.BEST_MODEL_PATH)
        for i in range(settings.SHOW_NUM):
            print(utils.generate_random_poetry(tokenizer, model))


# 创建数据生成器
data_generator = PoetryDataGenerator(poetry, batch_size=settings.BATCH_SIZE)
# 开始训练
model.fit_generator(data_generator.forfit(), steps_per_epoch=data_generator.steps, epochs=settings.TRAIN_EPOCHS,
                    callbacks=[Evaluate()])
