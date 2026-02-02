package orchestrator

import "log"

type Step interface {
	Up() error
	Down() error
	Name() string
}

type Orchestrator struct {
	steps []Step // The sequence of commands to execute (basically the workflow)
	done  []Step // Acts like a stack
}

// Initialises an orchestrator
func New(steps ...Step) *Orchestrator {
	return &Orchestrator{steps: steps}
}

// The whole workflow to get the AP up and running
func (o *Orchestrator) Up() error {

	// Execute each step in sequence
	for _, s := range o.steps {
		log.Printf("→ %s\n", s.Name())

		if err := s.Up(); err != nil {
			log.Printf("✗ %s failed: %v\n", s.Name(), err)
			o.Rollback() // Rolls back

			return err // For when the event stack concludes (The recursion)
		}

		o.done = append(o.done, s) // Saves the completed step in the stack
	}

	log.Println("We are airborne!")
	return nil
}

// Disables the AP in the event of a failure, or just for simply turning it off
func (o *Orchestrator) Rollback() {

	// Undoes each step backwards
	for i := len(o.done) - 1; i >= 0; i-- {
		s := o.done[i]
		_ = s.Down()

		log.Printf("← %s\n", s.Name())
	}

	o.done = nil
	log.Println("We are no longer airborne!")
}
