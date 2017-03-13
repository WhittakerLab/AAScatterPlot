%alignMultSeq will align sequences using the sw alignment protocol with
%respect to a reference sequence input.
%
%  OutSeq = alignMultSeq(RefSeq, Seq)
%
%  OutSeq = alignMultSeq(RefSeq, Seq, Alphabet)
%
%  OutSeq = alignMultSeq(RefSeq, Seq, Alphabet, MinScore)
% 
%  [OutSeq, Starts] = alignMultSeq(...)
%
%  INPUT
%    RefSeq: Reference sequence to align the rest of the sequences
%    Seq: Mx1 cell or char sequence that need to be aligned
%    Alphabet ['nt' 'aa' '']: The letter type
%    MinScore: Value from 0 to 100 %, for % of RefSeq to match to be valid
%
%  OUTPUT
%    OutSeq: A Mx1 cell array of aligned sequences.
%    Starts: A Mx1 matrix of where the aligned seq start based on the
%      original Seq
%
%  NOTE
%    If match is less than MinScore, will replace with '_'. 
%
%  EXAMPLE
%    RefSeq =  'ACGTGTG'        
%    Seq = {   'ACGTGTGGTG';    %Right extended
%           'GTTACGTGTG';       %Left extended
%              'ACGTG';         %Right short
%                'GTGTG';       %Left short
%              'ACGGTG';        %Missing a letter 
%              'ACGTTGTG';      %Has an extra letter
%            'TGACGTTGTG';      %Match, but not left end
%              'ACGTCGAAT';     %Match, but not right end
%              'CAGATCA' };     %No match
%    Alphabet = 'nt'
%    MinScore = 80;
%    [OutSeq, Starts] = alignMultSeq(RefSeq, Seq)
%    OutSeq = 
%         'ACGTGTG'
%         'ACGTGTG'
%         'ACGTGXX'
%         'XXGTGTG'
%         'ACG-GTG'
%         'ACGTGTG'
%         'ACGTGTG'
%         'ACGTCGA'
%         'AXGATCA'
%    Starts =
%          1
%          4
%          1
%         -2
%          1
%          1
%          3
%          1
%          2
%
%    [OutSeq, Starts] = alignMultSeq(RefSeq, Seq, 'nt', 60)
%    OutSeq = 
%         'ACGTGTG'
%         'ACGTGTG'
%         'XXXXXXX'
%         'XXXXXXX'
%         'ACG-GTG'
%         'ACGTGTG'
%         'XXXXXXX'
function [OutSeq, varargout] = alignMultSeq(RefSeq, Seq, varargin)
%Determine inputs
Alphabet = 'AA'; %Default
MinScore = 0; %Default
if length(varargin) >= 1
    if isempty(varargin{1}) || ismember(lower(varargin{1}),{'nt';'aa';''})
        Alphabet = varargin{1};
    end
    if length(varargin) >= 2 && isnumeric(varargin{2})
        MinScore = varargin{2};
    end
end

%Ensure MinScore is valid
if MinScore < 0
    warning('MinScore must be >= 0. Settinng to 0');
    MinScore = 0;
elseif MinScore > 100
    warning('MinScore must be <= 100. Setting to 100');
    MinScore = 100;
end

%Ensure proper format sequences
if iscell(RefSeq)
    RefSeq = upper(RefSeq{1});
else
    RefSeq = upper(RefSeq);
end
if ischar(Seq)
    Seq = {upper(Seq)};
else
    for j = 1:length(Seq)
        Seq{j} = upper(Seq{j});
    end
end

%Perform alignment to RefSeq
MinMatch = ceil(MinScore/100*length(RefSeq));
OutSeq = cell(length(Seq),1);
Starts = zeros(length(Seq),1);
for j = 1:length(Seq)
    [~, Alignment, StartAt] = swalign(RefSeq,Seq{j},'Alphabet',Alphabet);
    %Need to convert to absolute postion
    
    %See if the bottom has a insertion, which can't happen.
    TopSeqLoc = regexp(Alignment(1,:),'\w'); %Excludes the gap in topseq, '.'
    TopGapLoc = regexp(Alignment(1,:),'\-'); %Finds the gap in the top seq
    BotGapLoc = regexp(Alignment(3,:),'\-'); %Finds the gap in the botseq
    BotSeq = Alignment(3,TopSeqLoc);
    
    %How many letters left of Seq were excluded?
    if StartAt(1) > 1
        RecovCtL = StartAt(1) - 1; %How many nts of Seq2 must be recovered
        LeftoverL = StartAt(2) - 1; %How many nts of Seq2 that are leftover
        if RecovCtL > LeftoverL %Requires padding
            PadCtL = RecovCtL - LeftoverL;
            SeqL = Seq{j}(1:LeftoverL);
        else
            PadCtL = 0;
            SeqL = Seq{j}(StartAt(2) - RecovCtL: StartAt(2) - 1);
        end
        LeftPad = [repmat('X',1,PadCtL) SeqL];
    else
        LeftPad = '';
    end
    
    %How many letters right of RefSeq were excluded?
    if length(RefSeq) - StartAt(1) + 1 > length(BotSeq)
        RecovCtR = length(RefSeq) - length(LeftPad) - length(BotSeq);
        LeftoverR = length(Seq{j}) - (StartAt(2) - 1 + length(BotSeq) - length(BotGapLoc) + length(TopGapLoc)); 
        EndLoc = StartAt(2) + length(BotSeq) - length(BotGapLoc) - 1;
        if RecovCtR > LeftoverR %Requires padding
            PadCtR = RecovCtR - LeftoverR;        
            SeqR = Seq{j}(EndLoc+1:EndLoc+LeftoverR);
        else
            PadCtR = 0;
            SeqR = Seq{j}(EndLoc+1:EndLoc+RecovCtR);
        end
        RightPad = [repmat('X',1,PadCtR) SeqR];
    else
        RightPad = '';
    end

    %Check for match quality
    AlignedSeq = [LeftPad BotSeq RightPad];
    CurMatch = sum(AlignedSeq == RefSeq);
    Start = StartAt(2) - length(LeftPad);
    if Start <= 0; Start = Start - 1; end %Can't have 0 by convention. -2 -1 1 2 . 0 rserved for no start at.
    if CurMatch > MinMatch %Good enough match
        OutSeq{j} = AlignedSeq;
        Starts(j) = Start;
    else %Just set all to X
        OutSeq{j} = repmat('X',1,length(RefSeq));
        Starts(j) = 0;
    end
end

if nargout > 1
    varargout{1} = Starts;
end