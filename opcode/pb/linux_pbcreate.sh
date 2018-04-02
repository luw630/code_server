for file in ./*.proto
do
	protoc --cpp_out=./ --proto_path=./ $file
	protoc -I=. --descriptor_set_out=../../server/project/pb/$file $file
done
