function y =unNorm(yi,p)

    y = 0.5*(yi+1);
    y = p(1)*y + p(2);

end