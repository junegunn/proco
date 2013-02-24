Proco
=====

Proco is a lightweight asynchronous task executor service with a thread pool
especially designed for efficient batch processing of multiple items.

Producer-consumer
-----------------

Proco implements a traditional [producer-consumer model](http://en.wikipedia.org/wiki/Producer-consumer_problem)
where mutliple clients simultaneously submits (*produces*) items to be processed,
and threads in the thread pool process (*consumes*) items concurrently.
A client can asynchronously submit an item and optionally wait for its completion.
A submitted item is put into a fixed sized queue, which is then taken out by one of the executor threads.
In a highly concurrent environment a queue can become a point of contention,
thus Proco allows having multiple queues.
However, if you need strict serializability (FCFS), you should just have a single queue and a single executor thread.

Batch processing
----------------

Sometimes it really helps to process multiple items in bulk instead of one at a time.

Notable examples includes
- buffered disk I/O in Kernel
- consolidated e-mail notification
- database batch updates
- and group commit of database transactions.

In such scheme, we don't process a request as soon as it arrives,
but wait a little while hoping that we receive more requests as well,
so we can process them together with minimal amortized latency.

It's a pretty common pattern, that most developers will be writing similar scenarios
one way or another at some point. So why don't we make it reusable?


Installation
------------

Add this line to your application's Gemfile:

    gem 'proco'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install grouper

Basic usage
-----------

```ruby
require 'grouper'

grouper = Grouper.interval(0.1).     # Runs every 0.1 second
                  threads(4).        # 4 threads processing items every interval
                  tries(2).          # Retry on processing error
                  queue_size(1000)   # Each thread has a queue of size 1000

grouper.start do |items|
  # Batch-process items
  items.each_slice(100) do |slice|
    # ...
  end

  # Return code for the batch
end

# Synchronous submit
result = grouper.submit rand(1000)

# Asynchronous(!) submit (can block if the queue is full)
future = grouper.submit! rand(1000)

# Wait until the batch containing the item is processed
# (Commit notification)
result = future.get

# ...

# Process remaining submissions and terminate threads
grouper.exit

# Or, kill them instantly
# grouper.kill
```


Contributing
------------

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
