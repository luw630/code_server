#coding=utf-8
import os,sys,shutil
import zipfile
import os.path

class Helper():

	@staticmethod
	def createFolder(folder):
		if os.path.exists(folder):
			return

		paths = folder.split('/')
		tempPath = ""
		# print(paths)
		for path in paths:
			if path == "":
				continue

			tempPath = tempPath + path + "/"
			#print('path: ' + tempPath)
			if not os.path.exists(tempPath):
				os.mkdir(tempPath)


	@staticmethod
	def delFolder(folder):
		if os.path.exists(folder):
			shutil.rmtree(folder)

	@staticmethod
	def cleanFolder(folder):
		'''
		清理文件夹
		'''
		if os.path.exists(folder):
			shutil.rmtree(folder)

		Helper.createFolder(folder)

	@staticmethod
	def copy(copyFrom, copyTo):
		'''
		拷贝文件
		'''
		print(copyFrom, copyTo)
		if not os.path.exists(copyFrom):
			print('%s is not exist' %(copyFrom,))
			return


		if os.path.isfile(copyFrom):
			pos = copyTo.rfind('/')
			path = copyTo[:pos]
			if not os.path.exists(path):
				Helper.createFolder(path)

			shutil.copyfile(copyFrom, copyTo)

		elif os.path.isdir(copyFrom):
			if os.path.exists(copyTo):
				shutil.rmtree(copyTo)
			shutil.copytree(copyFrom, copyTo)

	@staticmethod
	def compileSource( srcDir, destFile):
		'''
			编译lua代码
		'''
		if os.path.exists(destFile):
			os.remove(destFile)
		quickPath = os.environ["QUICK_V3_ROOT"]
		cmd = quickPath + "/quick/bin/compile_scripts.bat -i " + srcDir + " -o " + destFile + " -m zip -e xxtea_chunk -ek vincent -es vincent"
		return os.system(cmd)

	@staticmethod
	def zipFolder(zipfilename,dirname):
		filelist = []
		if os.path.isfile(dirname):
			filelist.append(dirname)
		else :
			for root, dirs, files in os.walk(dirname):
				for name in files:
					filelist.append(os.path.join(root, name))

		zf = zipfile.ZipFile(zipfilename, "w", zipfile.zlib.DEFLATED)
		for tar in filelist:
			arcname = tar[len(dirname):]
			#print arcname
			zf.write(tar,arcname)
		zf.close()
	@staticmethod
	def unzipFoler(zipfilename, unziptodir):
		Helper.createFolder(unziptodir)
		zfobj = zipfile.ZipFile(zipfilename)
		for name in zfobj.namelist():
			name = name.replace('\\','/')
			print(name)
			if name.endswith('/'):
				print(os.path.join(unziptodir, name))
				os.mkdir(os.path.join(unziptodir, name))
			else:
				ext_filename = os.path.join(unziptodir, name)
				ext_dir= os.path.dirname(ext_filename)
				Helper.createFolder(ext_dir)
				outfile = open(ext_filename, 'wb')
				outfile.write(zfobj.read(name))
				outfile.close()

	@staticmethod
	def test():
		print('Helper.test')

	@staticmethod
	def copytree(src, dst, symlinks=False):
		if not os.path.exists(src):
			return
		
		names = os.listdir(src)
		if not os.path.isdir(dst):
			os.makedirs(dst)
			  
		errors = []
		for name in names:
			srcname = os.path.join(src, name)
			dstname = os.path.join(dst, name)
			try:
				if symlinks and os.path.islink(srcname):
					linkto = os.readlink(srcname)
					os.symlink(linkto, dstname)
				elif os.path.isdir(srcname):
					Helper.copytree(srcname, dstname, symlinks)
				else:
					if os.path.isdir(dstname):
						os.rmdir(dstname)
					elif os.path.isfile(dstname):
						os.remove(dstname)
					shutil.copy2(srcname, dstname)
				# XXX What about devices, sockets etc.?
			except (IOError, os.error) as why:
				errors.append((srcname, dstname, str(why)))
			# catch the Error from the recursive copytree so that we can
			# continue with other files
			except OSError as err:
				errors.extend(err.args[0])
		try:
			shutil.copystat(src, dst)
		except WindowsError:
			# can't copy file access times on Windows
			pass
		except OSError as why:
			errors.extend((src, dst, str(why)))
		if errors:
			raise Error(errors)

if __name__ == "__main__":
	Helper.test()
	path =sys.path[0]
	#Helper.zipFolder(path + "/games_tmkp.zip",path + "/games")
	#Helper.unzipFoler(path + "/games_tmkp.zip",path + "/test")


    