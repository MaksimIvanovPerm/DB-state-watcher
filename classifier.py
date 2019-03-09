import csv
import random
import math
import operator
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('-p', action='store',  nargs=1, dest='patterns_file', required=True, help='full path to file with marked pattern set')
parser.add_argument('-c', action='store',  nargs=1, dest='statevec_file', required=True, help='full path to file with current state vector')
args=parser.parse_args()
patterns_file=str(args.patterns_file[0])
statevec_file=str(args.statevec_file[0])


#print patterns_file+" "+statevec_file
#quit()

v_scale=1900
v_debug=0
 
def loadDataset(filename, trainingSet=[]):
	with open(filename, 'rb') as csvfile:
		lines = csv.reader(csvfile, delimiter=';')
		for row in lines:
			trainingSet.append(row)

def euclideanDistance(point1, point2):
	length=len(point1)
	distance = 0
	for x in range(length):
		distance += pow((float(point1[x]) - float(point2[x])), 2)
	return math.sqrt(distance)

def main():
	# load data from csv-file to list-arrays
	trainingSet=[]
		currentVect=[]
	loadDataset(patterns_file, trainingSet)
	loadDataset(statevec_file, currentVect)

	# try to find index of the nearest point in training set
	p1=currentVect[1][1:]
	p1=[float(x)*v_scale for x in p1]
	distance=float(0)
	x=0
	np_idx=0
	for i in range(1,len(trainingSet)): #skip headers
		p2=trainingSet[i][2:]
		distance=euclideanDistance(p1,p2)
		if i==1:
			x=distance
			np_idx=i
		else:
			if x > distance:
				x=distance
				np_idx=i
		if v_debug==1:
			print '%(snap_id)s\t%(flag_id)s\t%(dist)f' % {"snap_id":trainingSet[i][0], "flag_id":trainingSet[i][1], "dist":distance}
	# eof for-loop through training set of point;
	point_class=int(trainingSet[np_idx][1])
	dist2nearest_point=x
	if v_debug==1:
		print 'nearest point properties: %(snap_id)s class: %(flag_id)i distance: %(dist)f' % {"snap_id":trainingSet[np_idx][0], "flag_id":point_class, "dist":x}

	# if the nearest point belongs to class 0 (normal state of rdbms) then lets see how far, in average,
	# from the point, other class 0 points
	# And compare the distance from the current vec to the average dist
	if point_class==0:
		x=np_idx
		currentVect=[]
		for i in range(1,12,1):
			x+=1
			if x<len(trainingSet) and trainingSet[x][1]=="0":
				currentVect.append(x)
		x=np_idx
		for i in range(1,12,1):
			x-=1
			if x>0 and trainingSet[x][1]=="0":
				currentVect.append(x)
		distance=0
		p1=trainingSet[np_idx][2:]
		x=1
		np_idx=float(0)
		for i in currentVect:
			p2=trainingSet[i][2:]
			np_idx=euclideanDistance(p1,p2)
			if x==1:
				distance=np_idx
			else:
				if np_idx>distance:
					distance=np_idx
			x+=1
		# calculate average distance between given point and other point from class 0 and from the same time
		#distance=10*(distance/x)
		distance=distance
		if v_debug==1:
			print 'allowed locality near the point: %(dist)f' % {"dist":distance}
		if dist2nearest_point <= distance:
			print 'OK'
		else:
			print 'ALERT'
	else:
		print 'ALERT'
	
main()
