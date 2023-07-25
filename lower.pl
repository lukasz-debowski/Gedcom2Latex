#!/usr/bin/perl

my $id=shift;

while(<>){
    $_=~s/(\[id=$id)/\1,edges shift=-2mm/g;
    print;
}
