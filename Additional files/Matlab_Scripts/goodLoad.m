function [ outFile ] = goodLoad( filename )
%GOODLOAD Loads a mat file to a specific name

temp = load(filename);
fields = fieldnames(temp);
outFile = temp.(fields{1});    

end

