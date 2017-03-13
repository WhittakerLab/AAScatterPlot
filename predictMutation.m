%predictMutation takes a codon and predicts possible AA residues that can
%arise from a point mutation
%
%  AAPred = predictMutation(Codon)
%
%  [AAPred, AAFreq] = predictMutation(Codon)
%
%  INPUT
%    Codon: a 3-letter string containing A,C,G,T, or U.
%
%  OUTPUT
%    AAPred: the AA residues that can arise from a point mutation,
%      returned as a Mx1 char array
%    AAFreq: multiplicity of each possible mutantion, returned as a Mx1
%      matrix.

function varargout = predictMutation(Codon)
if length(Codon) ~= 3
    error('Codon must consist of a 3-letter character string');
end
Codon = upper(Codon);

%Convert U's to T's
ULocs = strfind(Codon,'U');
if isempty(ULocs) == 0
    Codon(ULocs) = 'T';
end

%Find all possible codons for single mutation
BP = 'GATC';
A = cell(9,1);
jj = 1;
for j = 1:3
    BPnot = BP(BP ~= Codon(j));
    for k = 1:3
        BPt = Codon;
        BPt(j) = BPnot(k);
        A{jj} = BPt;
        jj = jj+1;
    end
end
A = cell2mat(A);
NewAA = nt2aa(A);
NewAAStat = aacount(NewAA);
AAPred = fieldnames(NewAAStat);
AAFreq = cell2mat(struct2cell(NewAAStat));
AAPred = cell2mat(AAPred(AAFreq>0));
AAFreq = AAFreq(AAFreq>0);

if nargout >= 1
    varargout{1} = AAPred;
    if nargout == 2
        varargout{2} = AAFreq;
    end
end