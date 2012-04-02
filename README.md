# Effing Repo Management.

## Background

I love using FPM: <http://goo.gl/u3pJB> to create debian packages. It's an
awesome tool that takes all of the BS work to package debs and has made my life 
easier and more productive. 

However, after creating packages, the next pain-point is how to actually 
publish those packages for internal testing/verification and finally for public
consumption. That is, until FRM!

Previous solutions require you either to host your own repo and use several tools like 
reprepro along with a webserver, or to be confined to the requirements of a PPA.

## What is frm?

FRM is a simple solution for creating cloud-based repos. It is a small ruby 
library that pushes a specified set of deb packages into an Amazon s3 bucket 
allong with the required files and format needed to use it directly as a 
personal or public ubuntu mirror. 

It is designed to be the easiest way possible to host your own debian packages
on your own mirror without having to maintain any servers!

## Why is this good?

FRM provides some really cool benifits, such as:

* cloud based (no servers to maintain!)
* really easy to use
* can easily be backed backed by cloudfront to provide a worldwide geo-dns caching solution
* allows you to create unlimited seperate repos allowing for new possible dev/test workflows

## Install (currently only works on debian based systems)

Make sure you have a gpg key setup in ~/.gnupg

You can install frm with gem:

    gem install frm

Running it:

    frm -a AWS_ACCESS_KEY -s AWS_SECRET_KEY -b my_bucket -p some_path_inside_my_bucket package1 [package2] ...

## Currently Working:

* S3 support
* signed gpg release file (need to have a key setup in ~/.gnupg)
* all necessary configuration for Ubuntu natty 

## Known Issues

Although FRM is great, it's not perfect. Here are some things that we already know about: 

* can only create new repositories (merging into existing repos comming soon;)
* currently only works for natty (soon to be fixed)
* currently only works for debian packages (would be pretty easy to add support for rpm /me thinks. holler if u want)
* shells out to gpg (could not find a decent ruby solution to create detached signatures. plz holler if u know one!)
* shells out to 'dpkg' (may be fine)
* only works with Amazon S3 (could support another cloud if people want it)

## Need Help or Want to Contribute?

All contributions are welcome, please contact me if you need anything;) 

# Thanks!

Big thanks goes out to Jordan Sissel for creating FPM!

<https://github.com/jordansissel/fpm>
<https://github.com/jordansissel>
