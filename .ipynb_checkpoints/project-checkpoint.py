import keras
import tensorflow as tf
import numpy as np
import os
from keras.models import Model, Sequential
from keras.layers import Input, Conv1D, MaxPooling1D, BatchNormalization, Dense, Flatten,Layer,Embedding,Bidirectional,CuDNNLSTM,Dropout,TimeDistributed,Lambda,Activation,GlobalAveragePooling1D, Concatenate
#from keras.optimizers import Adam
from tensorflow.keras.optimizers import Adam
from keras.initializers import glorot_uniform,Ones, Zeros
from keras.losses import binary_crossentropy
from keras import backend as K
from keras import losses
import pandas as pd
from sklearn.model_selection import train_test_split

#Import file
os.chdir("../..")
dataframe = pd.read_csv("/nfs/turbo/umms-bleu-secure/trainingData/trainingData.csv")
data = dataframe.values

#Inputs and outputs
x = data[:,1:23]
y = data[:,23]

#min_max_scaler = preprocessing.MinMaxScaler()
#x = min_max_scaler.fit_transform(x)

#training and validation
xTrain, xValTest, yTrain, yValTest = train_test_split(x, y, test_size=0.3)
xVal, xTest, yVal, yTest = train_test_split(xValTest, yValTest, test_size=0.5)

#model
def dfnn():
    the_input= Input(shape=(22,))
    
    layer= Dense(16,activation = 'relu')(the_input) # 1 refers to how many things you want to predict
    layer= Dense(16,activation = 'relu')(layer) # 1 refers to how many things you want to predict

    y= Dense(1,activation = 'relu')(layer) # 1 refers to how many things you want to predict

    model = Model(inputs=[the_input], outputs=[y])
    model.compile(loss='mean_absolute_error', optimizer='adam',metrics = [tf.keras.metrics.MeanSquaredError()])

    return model

model = dfnn()

hist = model.fit(xTrain, yTrain,
          batch_size=32, epochs=100,
          validation_data=(xVal, yVal))

model.evaluate(xTest, yTest)[1]

yhat = model.predict(xTest)

index = 0
for i in yhat:
    print(str(i[0]) + " - " + str(y[index]) + " = " + str(int(i[0] - y[index])))
    index += 1