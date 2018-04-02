#coding:utf-8
import os,sys,shutil
from Helper import Helper
# sys.setdefaultencoding('utf-8')
curDir = os.path.dirname(__file__)
generate_pb_path = os.path.join(curDir,"pb")
Helper.delFolder(generate_pb_path)
Helper.createFolder(generate_pb_path)
dirFiles = os.listdir(curDir);
clientRootPath = os.path.join(curDir,"..","..","client")
pb_src_targetpath = os.path.join(clientRootPath,"new_client\\common\\pb")
pb_bit_targetPath = os.path.join(clientRootPath,"new_client\\res\hall\\res\\pb_files")
Helper.delFolder(pb_src_targetpath)
Helper.createFolder(pb_src_targetpath)
for file in dirFiles:
    if file.startswith("common_"):
    	if file.endswith(".proto"):
   	    	fileFullPath = os.path.join(curDir,file)
	    	targetFullPath = os.path.join(pb_src_targetpath,file)
	    	#generate pb files
	    	# client_create.bat
			# for /r %%s in (common_*.proto) do (
			# 	protoc.exe -I . --descriptor_set_out ./pb/%%~ns.proto %%~ns.proto
			# )
	    	systemStr = "protoc.exe -I . --descriptor_set_out ./pb/"+file+" "+file
	    	os.system(systemStr)
	    	shutil.copyfile(fileFullPath,targetFullPath)

pb_bite_files = os.listdir(generate_pb_path);
Helper.delFolder(pb_bit_targetPath)
Helper.createFolder(pb_bit_targetPath)
for file in pb_bite_files:
	if file.startswith("common_"):
		fileFullPath = os.path.join(generate_pb_path,file)
		targetFullPath = os.path.join(pb_bit_targetPath,file)
    	shutil.copyfile(fileFullPath,targetFullPath)
print "---------------end---------------------"


