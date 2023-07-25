#!/usr/bin/perl

# A simple Perl script to extract the most important fields of a
# GEDCOM formatted file to a family tree to be typeset with the
# genealogytree.sty LaTex package.

# USAGE

# ./gedcom2latex.pl find (name|id) NAME GEDCOM_FILE 

# ./gedcom2latex.pl (up|down|both) HEIGHT (short|long) (name|id) NAME_OR_ID GEDCOM_FILE > OUTPUT_FILE


use utf8;
use strict;

my $switch_tree=shift;
my $height_up;
my $height_down;
my $short;
my $switch_short;
if($switch_tree=~m/^(up|down|both)$/){
    if($switch_tree eq "up"){
	$height_up=shift;
    }elsif($switch_tree eq "down"){
	$height_down=shift;
    }elsif($switch_tree eq "both"){
	($height_down,$height_up)=split /-/,shift;
    }
    $switch_short=shift;
    if($switch_short eq "short"){ 
	$short=1;
    }elsif($switch_short eq "long"){
	$short=0;
    }
}elsif($switch_tree ne "find"){
    die "Unknown option!";
}
my $switch_name=shift;
my $main_name=shift;
my $file=shift;

my $person_id;
my $event;
my %sex;
my %given_names;
my %surname;
my %birth_date; my%birth_place;
my %death_date; my %death_place;

my $family_id;
my %spouses;
my %children;
my %marriage_date; my %marriage_place;

open(IN,$file);
while(<IN>){
    chomp;
    if(m|^0 @([^@]*)@ INDI|){
	$person_id=$1;
    }elsif(m|^0 @([^@]*)@ FAM|){
	$family_id=$1;
    }elsif(m|^0|){
	undef $person_id;
	undef $family_id;
	undef $event;
    }elsif(m|^1 SEX ([MF])|){
	if($1 eq "M"){
	    $sex{$person_id}=0; # if !defined $sex{$person_id};
	}elsif($1 eq "F"){
	    $sex{$person_id}=1; # if !defined $sex{$person_id};
	}
    }elsif(m|^1 NAME ([^/]*) /([^/]*)/|){ 
	# if(!defined $given_names{$person_id}){
	    $given_names{$person_id}=$1;
	    $surname{$person_id}=$2;
	    # print STDERR $person_id." ".$given_names{$person_id}."
	    # ".$surname{$person_id}."\n";
	# }
    }elsif(m|^1 BIRT|){
	$event=1;
    }elsif(m|^1 DEAT|){
	$event=2;
    }elsif(m|^1 MARR|){
	$event=3;
    }elsif(m|^1 FAMS @([^@]*)@|){
	$family_id=$1;
	$spouses{$family_id}[$sex{$person_id}]=$person_id;
    }elsif(m|^1 FAMC @([^@]*)@|){
	$family_id=$1;
	push @{$children{$family_id}},$person_id;
    }elsif(m|^1|){
	undef $event;
    }elsif((m|^2 DATE (.*\S)|)&&($event==1)){
	$birth_date{$person_id}=$1; # if !defined $birth_date{$person_id};
    }elsif((m|^2 DATE (.*\S)|)&&($event==2)){
	$death_date{$person_id}=$1; # if !defined $death_date{$person_id};
    }elsif((m|^2 DATE (.*\S)|)&&($event==3)){
	$marriage_date{$family_id}=$1; # if !defined $marriage_date{$family_id};
    }elsif((m|^2 PLAC (.*\S)|)&&($event==1)){
	$birth_place{$person_id}=$1; # if !defined $birth_place{$person_id};
    }elsif((m|^2 PLAC (.*\S)|)&&($event==2)){
	$death_place{$person_id}=$1; # if !defined $death_place{$person_id};
    }elsif((m|^2 PLAC (.*\S)|)&&($event==3)){
	$marriage_place{$family_id}=$1; # if !defined $marriage_place{$family_id};
    }
}
close(IN);

my %ancestor_family;
my %descendant_families;

for $family_id (keys %spouses){
    my $person_id;
    for $person_id (@{$spouses{$family_id}}){
	push @{$descendant_families{$person_id}},$family_id;
    }
    for $person_id (@{$children{$family_id}}){
	$ancestor_family{$person_id}=$family_id;
    }
}

sub sort_by_birth{
    my @persons=@_;
    return sort {date_to_string($birth_date{$a})<=>date_to_string($birth_date{$b})} @persons;
}

sub sort_by_marriage{
    my @families=@_;
    return sort {date_to_string($marriage_date{$a})<=>date_to_string($marriage_date{$b})} @families;
}

sub sex_to_string{
    my ($sex)=@_;
    if($sex==0){
	return "male";
    }elsif($sex==1){
	return "female";
    }
}	    

my @months=qw(JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC);
sub precise_date_to_string{
    my ($date)=@_;
    $date=uc($date);
    my $i;
    for $i (1..12){
	$date=~s/$months[$i-1]/$i/g;
    }
    $date=join "-",reverse(split /\s+/,$date);
    return $date;
}

sub date_to_string{
    my ($date)=@_;
    if($date=~m|^ABT (.*)|){
	return "(caAD)".precise_date_to_string($1);
    }elsif($date=~m|^AFT (.*)|){
	return precise_date_to_string($1)."/";
    }elsif($date=~m|^BEF (.*)|){
	return "/".precise_date_to_string($1);
    }elsif($date=~m|^BET (.*) AND (.*)|){
	return precise_date_to_string($1)."/".precise_date_to_string($2);
    }else{
	return precise_date_to_string($date);
    }
}	    

sub person_to_string{
    my ($person_id)=@_;
    if($short!=1){
	return "[id=$person_id]{"
	    .sex_to_string($sex{$person_id})
	    .",name={".$given_names{$person_id}
	." \\surn{".$surname{$person_id}
	."}},birth={".date_to_string($birth_date{$person_id})
	    ."}{".$birth_place{$person_id}
	."},death={".date_to_string($death_date{$person_id})
	    ."}{".$death_place{$person_id}
	."}}";
    }else{
	return "[id=$person_id]{"
	    .sex_to_string($sex{$person_id})
	    .",name={".$given_names{$person_id}
	." \\surn{".$surname{$person_id}
	."}},birth={".date_to_string($birth_date{$person_id})
	    ."}{"
	."},death={".date_to_string($death_date{$person_id})
	    ."}{"
	."}}";
    }	
}

# DEBUGGING:

# sub family_to_string{
#     my ($family_id)=@_;
#     my ($father,$mother)=@{$spouses{$family_id}};
#     my @persons=($father,$mother,@{$children{$family_id}});
#     my $string="";
#     my $person_id;
#     for $person_id (@persons){
# 	$string=$string.">".person_to_string($person_id);
#     }
#     return $string;
# }

# # for $person_id (sort keys %sex){
# #     print person_to_string($person_id)."\n";
# # }

# for $family_id (sort keys %spouses){
#     print family_to_string($family_id)."\n";
# }

# exit;

# END OF DEBUGGING


sub marriage_to_string{
    my ($family_id)=@_;
    if((defined $marriage_date{$family_id})&&($short!=1)){
	#return ",family database={marriage={".date_to_string($marriage_date{$family_id})."}{".$marriage_place{$family_id}."}}";
	return ",family database={marriage={".date_to_string($marriage_date{$family_id})."}{}}";
    }else{
	return "";
    }
}

my $blank="\t";
my %active_families;
my @merged_families;

sub ancestor_duplicate{
    my ($person_id)=@_;
    return 0 if (!exists $ancestor_family{$person_id});
    my  $family_id=$ancestor_family{$person_id};
    if(exists $active_families{$family_id}){
	push @merged_families,"add parent=$person_id to $family_id";
	return 1;
    }else{
	undef $active_families{$family_id};
	return 0;
    }
}

sub ancestor_family_to_string{
    my ($family_id,$my_person_id,$sandclock,$indent)=@_;
    my @persons=sort_by_birth @{$children{$family_id}};
    my $string="";
    my $person_id;
    for $person_id (@persons){
	if($person_id eq $my_person_id){	    
	    if($sandclock!=1){
		$string=$string.($blank x $indent)."g".person_to_string($person_id)."\n";
	    }
	}else{
	    if($short!=1){
		$string=$string.($blank x $indent)."c".person_to_string($person_id)."\n";
	    }
	}
    }
    return $string;
}

sub find_ancestors{
    my ($person_id,$height_up,$indent)=@_;  
    return "" if (!defined $person_id)||((!defined $given_names{$person_id})&&(!defined $surname{$person_id}));
    return ($blank x $indent)."p".person_to_string($person_id)."\n"
	if (!exists $ancestor_family{$person_id})||($height_up<1)||ancestor_duplicate($person_id);
    my $family_id=$ancestor_family{$person_id};
    return ($blank x $indent)."parent[id=$family_id".marriage_to_string($family_id)."]{\n"
	.ancestor_family_to_string($family_id,$person_id,0,$indent+1)
	.find_ancestors($spouses{$family_id}[0],$height_up-1,$indent+1)
	.find_ancestors($spouses{$family_id}[1],$height_up-1,$indent+1)
	.($blank x $indent)."}\n";
}

sub descendant_family_to_string{
    my ($family_id,$my_person_id,$union,$indent)=@_;
    my @persons=@{$spouses{$family_id}};
    my $string="";
    my $person_id;
    for $person_id (@persons){
	if($person_id eq $my_person_id){
	    if($union!=1){
		$string=$string.($blank x $indent)."g".person_to_string($person_id)."\n";
	    }
	}else{
	    if($short!=1){
		$string=$string.($blank x $indent)."p".person_to_string($person_id)."\n";
	    }
	}
    }
    return $string;
}

sub find_descendants{
    my ($person_id,$height_down,$indent)=@_;   
    return ($blank x $indent)."c".person_to_string($person_id)."\n"
	if  (!exists $descendant_families{$person_id})||($height_down<1);
    my @families=sort_by_marriage @{$descendant_families{$person_id}};
    my $family_id=$families[0];
    my $string="";
    $string=($blank x $indent)."child[id=$family_id".marriage_to_string($family_id)."]{\n"
	.descendant_family_to_string($family_id,$person_id,0,$indent+1)
	.join("",map find_descendants($_,$height_down-1,$indent+1),sort_by_birth @{$children{$family_id}});
    my $i;
    for $i (1..$#families){
	my $family_id=$families[$i];
	$string=$string.($blank x ($indent+1))."union[id=$family_id".marriage_to_string($family_id)."]{\n"
	    .descendant_family_to_string($family_id,$person_id,1,$indent+2)
	    .join("",map find_descendants($_,$height_down-1,$indent+2),sort_by_birth @{$children{$family_id}})
	    .($blank x ($indent+1))."}\n";
    }
    return $string.($blank x $indent)."}\n";
}

sub find_sandclock{
    my ($person_id,$height_down,$height_up,$indent)=@_;
    return "" 
	if (!exists $descendant_families{$person_id}); # ||($height_down<1);
    my $desc_family_id=$descendant_families{$person_id}[0];
    return ($blank x $indent)."sandclock[id=$person_id]{\n"
	.($blank x ($indent+1))."child[id=$desc_family_id".marriage_to_string($family_id)."]{\n"
	.descendant_family_to_string($desc_family_id,$person_id,0,$indent+2)
	.join("",map find_descendants($_,$height_down-1,$indent+2),@{$children{$desc_family_id}})
	.($blank x ($indent+1))."}\n"
	.($blank x $indent)."}\n"
	if (!exists $ancestor_family{$person_id})||($height_up<1)||ancestor_duplicate($person_id);
    my $anc_family_id=$ancestor_family{$person_id};
    return ($blank x $indent)."sandclock[id=$person_id]{\n"
	.ancestor_family_to_string($anc_family_id,$person_id,1,$indent+1)
	.($blank x ($indent+1))."child[id=$desc_family_id".marriage_to_string($family_id)."]{\n"
	.descendant_family_to_string($desc_family_id,$person_id,0,$indent+2)
	.join("",map find_descendants($_,$height_down-1,$indent+2),@{$children{$desc_family_id}})
	.($blank x ($indent+1))."}\n"
	.find_ancestors($spouses{$anc_family_id}[0],$height_up-1,$indent+1)
	.find_ancestors($spouses{$anc_family_id}[1],$height_up-1,$indent+1)
	.($blank x $indent)."}\n";
}
    
sub find_person_by_name{
    my  ($name)=@_;
    $name=uc($name);
    my $person_id;
    my @persons;
    for $person_id (keys %sex){
	my $person_name=uc($given_names{$person_id}." ".$surname{$person_id});
	push @persons,$person_id 
	    if $person_name=~m/$name/;
    }
    return @persons;
}

if($switch_tree=~m/^(up|down|both)$/){
    my $main_person_id;
    if($switch_name eq "name"){
	my @persons=find_person_by_name($main_name);
	if($#persons==0){
	    $main_person_id=$persons[0];
	}else{
	    print STDERR "There are following persons named '$main_name':\n";
	    for $person_id (sort @persons){
		print STDERR person_to_string($person_id)."\n";
	    }
	    die;
	}
    }elsif($switch_name eq "id"){
	if(exists $sex{$main_name}){	
	    $main_person_id=$main_name;
	}else{
	    print STDERR "There is no person with ID '$main_name':\n";
	    die;
	}
    }
    my $printout;
    if($switch_tree eq "up"){
	$printout=find_ancestors($main_person_id,$height_up,0) if defined $main_person_id;
    }elsif($switch_tree eq "down"){
	$printout=find_descendants($main_person_id,$height_down,0) if defined $main_person_id;
    }elsif($switch_tree eq "both"){
	$printout=find_sandclock($main_person_id,$height_down,$height_up,0) if defined $main_person_id;
    }
    my $infix=join(",",@merged_families,"");
    $printout=~s/^(sandclock|child|parent)\[/\1\[$infix/;
    print $printout;
}elsif($switch_tree eq "find"){
   if($switch_name eq "name"){
	my @persons=find_person_by_name($main_name);
	print "There are following persons named '$main_name':\n";
	for $person_id (sort @persons){
	    print person_to_string($person_id)."\n";
	}
   }elsif($switch_name eq "id"){
	if(exists $sex{$main_name}){	
	    print person_to_string($main_name);
	}else{
	    print "There is no person with ID '$main_name':\n";
	}
    }
}
exit;

   


