function [] = parsave( outFilepath, outStruct )
%PARSAVE Used for saving inside parfor loop. Saves the fields in outStruct
%to a mat file.

save(outFilepath,'-struct', 'outStruct');

end

