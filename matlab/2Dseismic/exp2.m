%% setup
f  = 5;
c0 = 2;
c1 = 2.5;
c2 = 2.25;

zr = [60:80:940];
xr = 60;
zs = [60:80:940];
xs = 940;

mfun = @(zz,xx)1./(c0 + (c1-c0)*exp(-5e-5*(xx(:)-300).^2 - 5e-5*(zz(:)-300).^2) + (c2-c0)*exp(-5e-5*(xx(:)-700).^2 - 5e-5*(zz(:)-700).^2)).^2;

sigma = .1;
alpha = 5;
%% data
n  = [101 101];
h  = [10 10];
z  = [0:n(1)-1]*h(1);
x  = [0:n(2)-1]*h(2);
[zz,xx] = ndgrid(z,x);

At = getA(f,mfun(zz,xx),h,n);
Pt = getP(h,n,zr,xr);
Qt = getP(h,n,zs,xs);
Dt = Pt'*(At\Qt);

noise = randn(size(Dt)); noise = sigma*noise*(norm(Dt(:))/norm(noise(:)));
SNR   = 20*log10(norm(Dt(:))/norm(noise(:)))
Dt    = Dt + noise;

%% inversion
n  = [51 51];
h  = [20 20];
z  = [0:n(1)-1]*h(1);
x  = [0:n(2)-1]*h(2);
[zz,xx] = ndgrid(z,x);

mref = mfun(zz,xx);

model.f = f;
model.n = n;
model.h = h;
model.zr = zr;
model.xr = xr;
model.zs = zs;
model.xs = xs;
model.mref = mref;

m0 = ones(prod(n),1)/c0.^2;
A0 = getA(f,m0,h,n);
P  = getP(h,n,zr,xr);
mu = real(eigmax(@(x)A0'\(P*P'*(A0\x)),prod(n)));

opts.maxit  = 20;
opts.M      = 5;
opts.tol    = 1e-9;
opts.lintol = 1e-1;
opts.method = 'GN';

% reduced
fh = @(m)phi(m,Dt,alpha,model);
[mr,infor] = QGNewton(fh,m0,opts);

% penalty
lambda = 1e-1*mu;
fh = @(m)phi_lambda(m,Dt,alpha,lambda,model);
[m1,info1] = QGNewton(fh,m0,opts);

lambda = 1e-0*mu;
fh = @(m)phi_lambda(m,Dt,alpha,lambda,model);
[m2,info2] = QGNewton(fh,m0,opts);

lambda = 1e1*mu;
fh = @(m)phi_lambda(m,Dt,alpha,lambda,model);
[m3,info3] = QGNewton(fh,m0,opts);

save('exp2');

%% plot
load('exp2');

plot2 = @(m)imagesc(x,z,reshape(m,n),[0.15 0.3]);

figure;plot2(mref);axis equal tight;ylabel('x_1 [m]');xlabel('x_2 [m]');colorbar;hold on; plot(xs,zs,'k*',xr,zr,'kv','markersize',10,'linewidth',2)

figure;
semilogy(sqrt(sum(infor(:,[5,6,7]).^2,2)),'k');hold on;
semilogy(sqrt(sum(info1(:,[5,6,7]).^2,2)),'r');hold on;
semilogy(sqrt(sum(info2(:,[5,6,7]).^2,2)),'b');hold on;
semilogy(sqrt(sum(info3(:,[5,6,7]).^2,2)),'g');
legend('reduced','\lambda = 0.1','\lambda = 1','\lambda = 10','location','northeast');
xlabel('iteration');ylabel('||\nabla L||_2');axis tight

figure;
plot(infor(:,8),'k');hold on;
plot(info1(:,8),'r');hold on;
plot(info2(:,8),'b');hold on;
plot(info3(:,8),'g');
legend('reduced','\lambda = 0.1','\lambda = 1','\lambda = 10','location','northeast');
xlabel('iteration');ylabel('|m^k - m^*||_2');axis tight

figure;plot2(mr);axis equal tight;ylabel('x_1 [m]');xlabel('x_2 [m]');
figure;plot2(m1);axis equal tight;ylabel('x_1 [m]');xlabel('x_2 [m]');
figure;plot2(m2);axis equal tight;ylabel('x_1 [m]');xlabel('x_2 [m]');
figure;plot2(m3);axis equal tight;ylabel('x_1 [m]');xlabel('x_2 [m]');

savefig(1:7,'../../doc/figs/2D_exp2');

table = [[1; 2].*infor(end,[1 2])' info1(end,[1 2])' info2(end,[1 2])' info3(end,[1 2])'];
latextable(table,'Horiz',{'reduced','$\lambda = 0.1$','$\lambda = 1$','$\lambda = 10$'},'Vert',{'iterations','PDE solves'},'Hline',[1 NaN],'format','%d','name','../../doc/figs/2D_exp2.tex');
