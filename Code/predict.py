from fastai.vision import *

defaults.device = torch.device('cpu')

#load resnet50 model

def DogBreedPred(img_path):
	learn2 = load_learner('models')

	img = open_image(img_path)

	pred_class,pred_idx,outputs = learn2.predict(img)

	top_breeds = pd.DataFrame(list(zip(learn2.data.classes, outputs.tolist())), columns =['Breed', 'Prob'])

	top_breeds['Breed'].replace(regex=True,inplace=True,to_replace=r'_',value=r' ')

	top_breeds['Breed'] = top_breeds['Breed'].str.capitalize()
	
	return top_breeds.sort_values('Prob',ascending=False).head()
	
#if __name__ == '__main__':
#	d = DogBreedPred('../test/labrador.jpg')
#	print(d)