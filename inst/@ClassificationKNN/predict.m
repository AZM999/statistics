## Copyright (C) 2023 Mohammed Azmat Khan <azmat.dev0@gmail.com>
##
## This file is part of the statistics package for GNU Octave.
##
## This program is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free Software
## Foundation; either version 3 of the License, or (at your option) any later
## version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along with
## this program; if not, see <http://www.gnu.org/licenses/>.
##
## -*- texinfo -*-
## @deftypefn  {statistics} {@var{label} =} knnpredict (@var{obj})
## @deftypefnx {statistics} {[@var{label}, @var{Score}, @var{cost}] =} knnpredict (@var{obj})
##
## Classify new data points into categries using kNN algorithm with object of
## of class ClassificationKNN.
##
## @itemize
## @item
## @code{obj} must be an object of class @code{ClassificationKNN}.
## @end itemize
## @end deftypefn
##

function [label, Score, cost] = predict (obj)

      ## Check Xclass
      if (isempty (obj.Xclass))
        error ("@ClassificationKNN.predict: Xclass is empty.");
      elseif (columns (obj.X) != columns (obj.Xclass))
        error ("@ClassificationKNN.predict: Xclass must have columns equal to X.");
      endif

      ## Check cost
      if (isempty (obj.cost))
        ## if empty assign all cost = 1
        obj.cost = ones (rows (obj.X), obj.NosClasses);
      endif

      if (isempty (obj.X))
        ## No data in X
        label     = repmat(classNames(1,:),0,1);
        posterior = NaN(0,classNos);
        cost      = NaN(0,classNos);
      else
        ## Calculate the NNs using knnsearch
        [idx, dist] = knnsearch (obj.X, obj.Xclass, "k", obj.k, ...
                     "NSMethod", obj.NSmethod, "Distance", obj.distance, ...
                     "P", obj.P, "Scale", obj.Scale, "cov", obj.cov, ...
                     "bucketsize", obj.bucketsize, "sortindices", true, ...
                     "includeties",obj.Includeties);

        [label, Score, cost_temp] = predictlabel (obj, idx);

        cost  = obj.cost(rows(cost_temp),columns(cost_temp)) .* cost_temp;

        ## Store predcited in the object variables

        obj.NN    = idx;
        obj.label = label;
        obj.Score = Score;
        obj.cost  = cost;

      endif

endfunction

## Function predict label
function [labels, Score, cost_temp] = predictlabel (obj, idx)
  ## Assign intial values
  freq = [];
  wsum  = sum (obj.weights);
  Score = [];
  labels = [];
  cost_temp = [];

  for i = 1:rows (idx)
    if (!isempty (obj.weights))
      ## Weighted kNN
      for id = 1:numel (obj.classNames)
        freq = [freq; (sum (strcmpi (obj.classNames(id,1), obj.Y(idx(i,:))) .* obj.weights)) / wsum;]
        Score_temp = (freq ./ obj.k)';
      endfor
    else
      ## Non-weighted kNN
      for id = 1:size (obj.classNames,1) #u{iu(:),2}
        freq(id,1) = (sum (strcmpi (obj.classNames(id,1), obj.Y(idx(i,:)))));
      endfor
      ## Score calculation
      Score_temp = (freq ./ obj.k)';
      cost_temp  = [cost_temp; ones(1,obj.NosClasses) - Score_temp];
      Score = [Score; Score_temp];
    endif

    [val, iu] = max (freq);

    ## Set label for the index idx
    labels = [labels; obj.classNames(iu,1)];

  endfor

endfunction

%!demo
%! ## find 10 nearest neighbour of a point using different distance metrics
%! ## and compare the results by plotting
%! load fisheriris
%! x = meas;
%! y = species;
%! xnew = [5, 3, 5, 1.45];
%! ## create an object
%! a = fitcknn (x, y, 'Xclass' , xnew, 'k', 5)
%! ## predict labels for points in xnew
%! predict (a)
%! ## change properties keeping training data and predict again
%! a.distance = 'hamming';
%! a.k = 10;
%! predict (a)

## Test output
%!shared x, y
%! load fisheriris
%! x = meas;
%! y = species;
%!test
%! xnew = [min(x);mean(x);max(x)];
%! obj  = ClassificationKNN (x, y, 'xclass', xnew, "k", 5);
%! [l, s, c] = predict (obj);
%! assert (l, {"setosa";"versicolor";"virginica"})
%! assert (s, [1, 0, 0;0, 1, 0;0, 0, 1])
%! assert (c, [0, 1, 1;1, 0, 1;1, 1, 0])
%!test
%! xnew = [min(x);mean(x);max(x)];
%! obj  = ClassificationKNN (x, y, 'xclass', xnew, "k", 10, "distance", "mahalanobis");
%! [l, s, c] = predict (obj);
%! assert (s, [0.3000, 0.7000, 0;0, 0.9000, 0.1000;0.2000, 0.2000, 0.6000], 1e-4)
%! assert (c, [0.7000, 0.3000, 1.0000;1.0000, 0.1000, 0.9000;0.8000, 0.8000, 0.4000], 1e-4)
%!test
%! xnew = [min(x);mean(x);max(x)];
%! obj  = ClassificationKNN (x, y, 'xclass', xnew, "k", 10, "distance", "cosine");
%! [l, s, c] = predict (obj);
%! assert (l, {"setosa";"versicolor";"virginica"})
%! assert (s, [1.0000, 0, 0;0, 1.0000, 0;0, 0.3000, 0.7000], 1e-4)
%! assert (c, [0, 1.0000, 1.0000;1.0000, 0, 1.0000;1.0000, 0.7000, 0.3000], 1e-4)
%!test
%! xnew = [5.2, 4.1, 1.5,	0.1;5.1,	3.8,	1.9,	0.4;5.1,	3.8, 1.5,	0.3;4.9,	3.6,	1.4,	0.1];
%! obj  = ClassificationKNN (x, y, 'xclass', xnew, "k", 5);
%! [l, s, c] = predict (obj);
%! assert (l, {"setosa";"setosa";"setosa";"setosa"})
%! assert (s, [1, 0, 0;1, 0, 0;1, 0, 0;1, 0, 0])
%! assert (c, [0, 1, 1;0, 1, 1;0, 1, 1;0, 1, 1])
%!test
%! xnew = [5, 3, 5, 1.45];
%! obj  = ClassificationKNN (x, y, 'xclass', xnew, "k", 5);
%! [l, s, c] = predict (obj);
%! assert (l, {"versicolor"})
%! assert (s, [0, 0.6000, 0.4000], 1e-4)
%! assert (c, [1.0000, 0.4000, 0.6000], 1e-4)
%!test
%! xnew = [5, 3, 5, 1.45];
%! obj  = ClassificationKNN (x, y, 'xclass', xnew, "k", 10, "distance", "minkowski", "P", 5);
%! [l, s, c] = predict (obj);
%! assert (l, {"versicolor"})
%! assert (s, [0, 0.5000, 0.5000], 1e-4)
%! assert (c, [1.0000, 0.5000, 0.5000])
%!test
%! xnew = [5, 3, 5, 1.45];
%! obj  = ClassificationKNN (x, y, 'xclass', xnew, "k", 10, "distance", "jaccard");
%! [l, s, c] = predict (obj);
%! assert (l, {"setosa"})
%! assert (s, [0.9000, 0.1000, 0], 1e-4)
%! assert (c, [0.1000, 0.9000, 1.0000], 1e-4)
%!test
%! xnew = [5, 3, 5, 1.45];
%! obj  = ClassificationKNN (x, y, 'xclass', xnew, "k", 10, "distance", "mahalanobis");
%! [l, s, c] = predict (obj);
%! assert (l, {"versicolor"})
%! assert (s, [0.1000, 0.5000, 0.4000], 1e-4)
%! assert (c, [0.9000, 0.5000, 0.6000], 1e-4)
%!test
%! xnew = [5, 3, 5, 1.45];
%! obj  = ClassificationKNN (x, y, 'xclass', xnew, "k", 5, "distance", "jaccard");
%! [l, s, c] = predict (obj);
%! assert (l, {"setosa"})
%! assert (s, [0.8000, 0.2000, 0], 1e-4)
%! assert (c, [0.2000, 0.8000, 1.000], 1e-4)
%!test
%! xnew = [5, 3, 5, 1.45];
%! obj  = ClassificationKNN (x, y, 'xclass', xnew, "k", 5, "distance", "seuclidean");
%! [l, s, c] = predict (obj);
%! assert (l, {"versicolor"})
%! assert (s, [0, 1, 0], 1e-4)
%! assert (c, [1, 0, 1], 1e-4)
%!test
%! xnew = [5, 3, 5, 1.45];
%! obj  = ClassificationKNN (x, y, 'xclass', xnew, "k", 10, "distance", "chebychev");
%! [l, s, c] = predict (obj);
%! assert (l, {"versicolor"})
%! assert (s, [0, 0.7000, 0.3000], 1e-4)
%! assert (c, [1.000, 0.3000, 0.7000], 1e-4)
%!test
%! xnew = [5, 3, 5, 1.45];
%! obj  = ClassificationKNN (x, y, 'xclass', xnew, "k", 10, "distance", "cityblock");
%! [l, s, c] = predict (obj);
%! assert (l, {"versicolor"})
%! assert (s, [0, 0.6000, 0.4000], 1e-4)
%! assert (c, [1.000, 0.4000, 0.6000], 1e-4)
%!test
%! xnew = [5, 3, 5, 1.45];
%! obj  = ClassificationKNN (x, y, 'xclass', xnew, "k", 10, "distance", "manhattan");
%! [l, s, c] = predict (obj);
%! assert (l, {"versicolor"})
%! assert (s, [0, 0.6000, 0.4000], 1e-4)
%! assert (c, [1.000, 0.4000, 0.6000], 1e-4)
%!test
%! xnew = [5, 3, 5, 1.45];
%! obj  = ClassificationKNN (x, y, 'xclass', xnew, "k", 10, "distance", "cosine");
%! [l, s, c] = predict (obj);
%! assert (l, {"virginica"})
%! assert (s, [0, 0.1000, 0.9000], 1e-4)
%! assert (c, [1.000, 0.9000, 0.1000], 1e-4)
%!test
%! xnew = [5, 3, 5, 1.45];
%! obj  = ClassificationKNN (x, y, 'xclass', xnew, "k", 10, "distance", "correlation");
%! [l, s, c] = predict (obj);
%! assert (l, {"virginica"})
%! assert (s, [0, 0.1000, 0.9000], 1e-4)
%! assert (c, [1.000, 0.9000, 0.1000], 1e-4)
%!test
%! xnew = [5, 3, 5, 1.45];
%! obj  = ClassificationKNN (x, y, 'xclass', xnew, "k", 30, "distance", "spearman");
%! [l, s, c] = predict (obj);
%! assert (l, {"versicolor"})
%! assert (s, [0, 1, 0], 1e-4)
%! assert (c, [1, 0, 1], 1e-4)
%!test
%! xnew = [5, 3, 5, 1.45];
%! obj  = ClassificationKNN (x, y, 'xclass', xnew, "k", 30, "distance", "hamming");
%! [l, s, c] = predict (obj);
%! assert (l, {"setosa"})
%! assert (s, [0.4333, 0.3333, 0.2333], 1e-4)
%! assert (c, [0.5667, 0.6667, 0.7667], 1e-4)
%!test
%! xnew = [5, 3, 5, 1.45];
%! obj  = ClassificationKNN (x, y, 'xclass', xnew, "k", 5, "distance", "hamming");
%! [l, s, c] = predict (obj);
%! assert (l, {"setosa"})
%! assert (s, [0.8000, 0.2000, 0], 1e-4)
%! assert (c, [0.2000, 0.8000, 1.0000], 1e-4)
%!test
%! xnew = [min(x);mean(x);max(x)];
%! obj  = ClassificationKNN (x, y, 'xclass', xnew, "k", 10, "distance", "correlation");
%! [l, s, c] = predict (obj);
%! assert (l, {"setosa";"versicolor";"virginica"})
%! assert (s, [1.0000, 0, 0;0, 1.0000, 0;0, 0.4000, 0.6000], 1e-4)
%! assert (c, [0, 1.0000, 1.0000;1.0000, 0, 1.0000;1.0000, 0.6000, 0.4000], 1e-4)
%!test
%! xnew = [min(x);mean(x);max(x)];
%! obj  = ClassificationKNN (x, y, 'xclass', xnew, "k", 10, "distance", "hamming");
%! [l, s, c] = predict (obj);
%! assert (l, {"setosa";"setosa";"setosa"})
%! assert (s, [0.9000, 0.1000, 0;1.000, 0, 0;0.5000, 0, 0.5000], 1e-4)
%! assert (c, [0.1000, 0.9000, 1.0000;0, 1.0000, 1.0000;0.5000, 1.0000, 0.5000], 1e-4)
