package main

import (
	"flag"
	"sync"
	"time"

	"github.com/go-pg/pg"
	"github.com/go-pg/pg/orm"
	"github.com/pkg/errors"
	"github.com/sirupsen/logrus"
	"github.com/tjarratt/babble"
)

type Person struct {
	ID   int    `sql:"id"`
	Name string `sql:"name"`
}

const (
	wordsCount      = 5
	records         = 8500000
	insertDbPortion = 25000
	insertWorkers   = 2
	errorsBuffer    = 2 * insertWorkers
)

var babbler = babble.NewBabbler() // random phrases generator
func main() {
	var connectionString string
	flag.StringVar(&connectionString, "postgres", "postgres://postgres:postgres@postgres:5432/people?sslmode=disable", "connection string for postgres")
	flag.Parse()
	babbler.Separator = " "
	babbler.Count = wordsCount
	db, err := connectToPostgresTimeout(connectionString, 10*time.Second, time.Second)
	if err != nil {
		logrus.Fatalf("%+v", err)
	}
	/*if err := createSchema(db); err != nil {
		logrus.Fatalf("%+v", err)
	}*/
	if err := fill(records, db); err != nil {
		logrus.Fatalf("%+v", err)
	}
}

func fill(count int, db *pg.DB) error {
	companiesToInsert := make(chan []interface{})
	errs := make(chan error, errorsBuffer)
	go func() {
		var bunch []interface{}
		for i := 0; i < count; i++ {
			p := &Person{Name: babbler.Babble()}
			bunch = append(bunch, p)
			if len(bunch) >= insertDbPortion {
				companiesToInsert <- bunch
				logrus.Infof("sent group of %d people to chan: %d of %d", len(bunch), i, count)
				bunch = []interface{}{}
			}
		}
		if len(bunch) > 0 {
			companiesToInsert <- bunch
			logrus.Infof("sent final group of %d people to chan", len(bunch))

		}
		close(companiesToInsert)
	}()
	wg := sync.WaitGroup{}
	for i := 0; i < insertWorkers; i++ {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			for cc := range companiesToInsert {
				t1 := time.Now()
				if err := db.Insert(cc...); err != nil {
					err = errors.Wrap(err, "couldn't save people")
					errs <- err
					return
				}
				logrus.Infof("saved %d people: %s, worker: %d", insertDbPortion, time.Since(t1), i)
			}
		}(i)
	}
	done := make(chan bool)
	go func() {
		wg.Wait()
		done <- true
	}()
	select {
	case err := <-errs:
		err = errors.WithStack(err)
		return err
	case <-done:
	}
	return nil
}

func connectToPostgresTimeout(connectionString string, timeout, retry time.Duration) (*pg.DB, error) {
	var (
		connectionError error
		db              *pg.DB
	)
	connected := make(chan bool)
	go func() {
		for {
			db, connectionError = connectToPostgres(connectionString)
			if connectionError != nil {
				time.Sleep(retry)
				continue
			}
			connected <- true
			break
		}
	}()
	select {
	case <-time.After(timeout):
		err := errors.Wrapf(connectionError, "timeout %s connecting to db", timeout)
		return nil, err
	case <-connected:
	}
	return db, nil
}

func connectToPostgres(connectionString string) (*pg.DB, error) {
	opt, err := pg.ParseURL(connectionString)
	if err != nil {
		return nil, errors.Wrap(err, "connecting to postgres with connection string: "+connectionString)
	}

	db := pg.Connect(opt)
	_, err = db.Exec("SELECT 1")
	if err != nil {
		err = errors.WithStack(err)
		return nil, err
	}

	return db, nil
}

func createSchema(db *pg.DB) error {
	for _, model := range []interface{}{(*Person)(nil)} {
		err := db.CreateTable(model, &orm.CreateTableOptions{
		//Temp: true,
		})
		if err != nil {
			return err
		}
	}
	return nil
}
